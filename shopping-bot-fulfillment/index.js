const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cors = require('cors');
const serviceAccount = require('./multi-vendor-store-df606-firebase-adminsdk-fbsvc-d811684664.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://multi-vendor-store-df606.firebaseio.com'
});

const db = admin.firestore();
const app = express();
app.use(cors({
  origin: '*',
  methods: ['POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(bodyParser.json());

app.post('/webhook', async (req, res) => {
  console.log('Webhook call received:', JSON.stringify(req.body, null, 2));
  
  // Extract the intent information
  const intent = req.body.queryResult.intent.displayName;
  console.log('Intent received:', intent);
  
  // Normalize intent name for case-insensitive matching
  const normalizedIntent = intent.toLowerCase();
  const parameters = req.body.queryResult.parameters || {};
  let outputContexts = req.body.queryResult.outputContexts || [];
  const queryParams = req.body.queryResult.queryParams || {};
  const originalPayload = req.body.originalDetectIntentRequest?.payload;
  
  // Initialize buyerId and try all possible locations
  let buyerId = null;
  
  // Log request structure for debugging
  console.log('Request structure:', {
    originalDetectIntentRequest: req.body.originalDetectIntentRequest,
    payload: originalPayload,
    queryParams: req.body.queryResult.queryParams
  });

  // Try to get buyerId from all possible locations
  // 1. Try queryParams payload first (comes from the app)
  if (req.body.queryResult?.queryParams?.payload?.buyerId) {
    buyerId = req.body.queryResult.queryParams.payload.buyerId;
    console.log('Found buyerId in queryParams payload:', buyerId);
  }
  
  // 2. Try originalDetectIntentRequest payload
  if (!buyerId && req.body.originalDetectIntentRequest?.payload?.buyerId) {
    buyerId = req.body.originalDetectIntentRequest.payload.buyerId;
    console.log('Found buyerId in originalDetectIntentRequest payload:', buyerId);
  }

  // 3. Try contexts
  if (!buyerId) {
    const userContext = req.body.queryResult.outputContexts?.find(ctx => 
      ctx.name.endsWith('user-context') || 
      ctx.name.endsWith('buyer-context')
    );
    if (userContext?.parameters?.buyerId) {
      buyerId = userContext.parameters.buyerId;
      console.log('Found buyerId in context:', buyerId);
    }
  }

  // Log final resolved buyerId
  console.log('Final resolved buyerId:', buyerId || 'Not found');
  
  // Get orderId parameter
  const orderId = parameters.orderId;
  
  // Extract contexts for specific uses
  const userContext = outputContexts.find(context => 
    context.name.endsWith('user-context') || 
    context.name.endsWith('buyer-context') ||
    context.name.endsWith('user_context')
  );
  
  const recommendationContext = outputContexts.find(context => 
    context.name.endsWith('recommendation-context') ||
    context.name.endsWith('recommendation_context')
  );
  
  // Debug raw contexts found
  if (userContext) console.log('Found user context:', JSON.stringify(userContext));
  if (recommendationContext) console.log('Found recommendation context:', JSON.stringify(recommendationContext));
  
  // Handle authentication check
  if (buyerId && buyerId !== 'anonymous' && buyerId !== '') {
    console.log('Valid buyerId found:', buyerId);
    
    // Create new contexts array with updated buyerId
    const updatedContexts = outputContexts.map(ctx => {
      if (ctx.name.endsWith('user-context') || ctx.name.endsWith('buyer-context')) {
        return {
          ...ctx,
          parameters: { ...ctx.parameters, buyerId }
        };
      }
      return ctx;
    });
    
    // Use the updated contexts array
    outputContexts = updatedContexts;
  } else {
    console.log('buyerId is missing or anonymous');
    buyerId = 'anonymous';

    // For intents that require authentication, return early with sign-in message
    if (normalizedIntent === 'getorders' || normalizedIntent === 'getorderdetails' || 
        intent === 'UpdateOrderAddress' || intent === 'GetRecommendations') {
      console.log('Authentication required for intent:', intent);
      return res.json({
        fulfillmentText: 'Please sign in to use this feature.',
        outputContexts: [createContext('user_signin_needed', 2, {})]
      });
    }
  }
  
  // Create a helper function for context creation
  function createContext(name, lifespanCount, parameters) {
    return {
      name: `projects/multi-vendor-store-df606/agent/sessions/${req.body.session.split('/').pop()}/contexts/${name}`,
      lifespanCount,
      parameters
    };
  }

  // Implement intent handlers
  if (intent === 'GetRecommendations' || intent === 'GetAnotherRecommendation') {
    try {
      // Log recommendation processing
      console.log('Processing GetRecommendations intent');
      
      // If this is GetAnotherRecommendation and we have a recommendation context, get buyerId from there
      if (intent === 'GetAnotherRecommendation' && recommendationContext?.parameters?.buyerId) {
        buyerId = recommendationContext.parameters.buyerId;
      }
      
      // Eğer anonim kullanıcı ise genel öneriler yap
      if (buyerId === 'anonymous') {
        const vendorsSnapshot = await db.collection('vendors')
          .where('approved', '==', true)
          .limit(1)
          .get();

        if (!vendorsSnapshot.empty) {
          const vendorDoc = vendorsSnapshot.docs[0];
          const vendorData = vendorDoc.data();
          return res.json({
            fulfillmentText: `While you haven't signed in yet, I recommend checking out ${vendorData.bussinessName}!RECOMMENDATION_BUTTON{"type":"vendor","data":{"vendorId":"${vendorDoc.id}","action":"openVendor"}}`
          });
        }
      }

      // Kayıtlı kullanıcı için kişiselleştirilmiş öneriler
      // Get user's order history
      const ordersSnapshot = await db.collection('orders')
        .where('buyerId', '==', buyerId)
        .orderBy('orderDate', 'desc')
        .get();

      if (ordersSnapshot.empty) {
        // If user has no orders, recommend a random approved vendor
        const vendorsSnapshot = await db.collection('vendors')
          .where('approved', '==', true)
          .limit(1)
          .get();

        if (vendorsSnapshot.empty) {
          return res.json({
            fulfillmentText: 'I apologize, but I couldn\'t find any vendors to recommend right now.'
          });
        }

        const randomVendor = vendorsSnapshot.docs[0];
        const vendorData = randomVendor.data();
        // Format the message exactly as expected by Flutter
        return res.json({
          fulfillmentText: `While you haven't made any orders yet, I recommend checking out ${vendorData.bussinessName}!RECOMMENDATION_BUTTON{"type":"vendor","data":{"vendorId":"${randomVendor.id}","action":"openVendor"}}`
        });
      }

      // Analyze order history to track vendors and categories
      const vendorStats = {};
      const categoryStats = {};
      let lastOrderDate = null;

      ordersSnapshot.forEach(doc => {
        const data = doc.data();
        const orderDate = data.orderDate.toDate();
        
        if (!lastOrderDate || orderDate > lastOrderDate) {
          lastOrderDate = orderDate;
        }

        // Track vendor frequency and total spent
        if (!vendorStats[data.vendorId]) {
          vendorStats[data.vendorId] = {
            frequency: 0,
            totalSpent: 0,
            lastOrderDate: orderDate
          };
        }
        vendorStats[data.vendorId].frequency++;
        vendorStats[data.vendorId].totalSpent += data.productPrice * data.quantity;
        if (orderDate > vendorStats[data.vendorId].lastOrderDate) {
          vendorStats[data.vendorId].lastOrderDate = orderDate;
        }
      });

      // Calculate vendor scores based on multiple factors
      const vendorScores = {};
      const now = new Date();
      Object.entries(vendorStats).forEach(([vendorId, stats]) => {
        // Calculate recency score (higher for more recent orders)
        const daysSinceLastOrder = (now - stats.lastOrderDate) / (1000 * 60 * 60 * 24);
        const recencyScore = Math.exp(-daysSinceLastOrder / 30); // Exponential decay over 30 days

        // Calculate frequency and monetary scores
        const frequencyScore = stats.frequency;
        const monetaryScore = stats.totalSpent;

        // Combine scores with weights          // Add randomness to make recommendations more diverse
          const randomFactor = Math.random() * 0.2; // 20% random variation
          vendorScores[vendorId] = 
            (0.35 * recencyScore) + // Recency is important
            (0.25 * frequencyScore) + // Frequency shows loyalty
            (0.25 * (monetaryScore / 1000)) + // Monetary value normalized by 1000
            (0.15 * randomFactor); // Random factor to increase variety
      });

      // Get top 3 vendors by score
      const topVendorIds = Object.entries(vendorScores)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 3)
        .map(([vendorId]) => vendorId);

      // Get a random vendor from top 3
      const recommendedVendorId = topVendorIds[Math.floor(Math.random() * topVendorIds.length)];

      // Get vendor details
      const vendorDoc = await db.collection('vendors').doc(recommendedVendorId).get();
      
      if (!vendorDoc.exists) {
        return res.json({
          fulfillmentText: 'I apologize, but I couldn\'t find the vendor information right now.'
        });
      }

      const vendorData = vendorDoc.data();
      if (!vendorData || !vendorData.bussinessName) {
        return res.json({
          fulfillmentText: 'I apologize, but I couldn\'t find valid vendor information.'
        });
      }
      
      const vendorName = vendorData.bussinessName;
      // Create recommendation message with button, exactly matching Flutter's expected format
      // Düzenleme: RECOMMENDATION_BUTTON: yerine RECOMMENDATION_BUTTON kullanıyoruz, Flutter'ın beklediği format bu
      const recommendationMessage = `I think you might enjoy ${vendorName} based on your shopping preferences!RECOMMENDATION_BUTTON{"type":"vendor","data":{"vendorId":"${recommendedVendorId}","action":"openVendor"}}`;

      res.json({
        fulfillmentText: recommendationMessage
      });

    } catch (error) {
      console.error('Error in GetRecommendations:', error);
      res.json({
        fulfillmentText: 'Sorry, I encountered an error while getting recommendations.'
      });
    }  } else if (normalizedIntent === 'getorders') {    try {
      console.log('Processing getorders intent with buyerId:', buyerId);
      
      // Anonymous users are already handled by the main buyerId check above
      // Here we just need to verify buyerId is valid
      if (!buyerId || buyerId === 'anonymous') {
        console.log('No valid buyerId found for getorders intent');
        return res.json({
          fulfillmentText: 'Please sign in to view your orders.',
          outputContexts: [createContext('user_signin_needed', 2, {})]
        });
      }

      // Fetch orders from Firestore
      console.log(`Querying orders for buyerId: ${buyerId}`);
      const ordersSnapshot = await db.collection('orders')
        .where('buyerId', '==', buyerId)
        .get();

      if (ordersSnapshot.empty) {
        console.log('No orders found for user');
        res.json({
          fulfillmentText: 'You don\'t have any orders yet.'
        });
        return;
      }

      // Process orders
      const orders = [];
      ordersSnapshot.forEach(doc => {
        const data = doc.data();
        orders.push({
          orderId: doc.id,
          productName: data.productName,
          scheduleDate: data.scheduleDate,
          accepted: data.accepted
        });
      });

      // Format order list
      const orderList = orders.map(order => {
        const status = order.accepted ? 'Accepted' : 'Pending';
        const date = new Date(order.scheduleDate).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
        return `${order.productName} (Order ID: ${order.orderId}) - Delivery Date: ${date}, Status: ${status}`;
      }).join('\n');

      console.log('Sending orders response with context');
      res.json({
        fulfillmentText: `Here are your orders:\n${orderList}`,
        outputContexts: [
          // Maintain user context with buyer ID
          createContext('user-context', 5, {
            buyerId: buyerId,
            lastAction: 'getOrders'
          })
        ]
      });

    } catch (error) {
      console.error('GetOrders intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while retrieving your orders.'
      });
    }  } else if (normalizedIntent === 'getorderdetails') {
    try {
      // Get effective buyer ID from context if available
      const contextBuyerId = userContext?.parameters?.buyerId || userContext?.parameters?.userIdentifier;
      const effectiveBuyerId = contextBuyerId || buyerId;
      
      if (!effectiveBuyerId || effectiveBuyerId === 'anonymous') {
        return res.json({
          fulfillmentText: 'Please sign in to view your order details.',
          outputContexts: [createContext('user_signin_needed', 2, {})]
        });
      }

      if (!orderId) {
        res.json({
          fulfillmentText: 'Please provide an order ID to get the details.'
        });
        return;
      }

      const orderDoc = await db.collection('orders').doc(orderId).get();
      
      if (!orderDoc.exists) {
        res.json({
          fulfillmentText: 'Order not found. Please check the order ID and try again.'
        });
        return;
      }      const orderData = orderDoc.data();
      
      // Verify that this order belongs to the requesting user
      if (orderData.buyerId !== effectiveBuyerId) {
        console.log(`Order belongs to ${orderData.buyerId}, not ${effectiveBuyerId}`);
        res.json({
          fulfillmentText: 'This order does not belong to your account.'
        });
        return;
      }

      const date = new Date(orderData.scheduleDate).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
      const status = orderData.accepted ? 'Accepted' : 'Pending';
      const details = [
        `Product: ${orderData.productName}`,
        `Status: ${status}`,
        `Delivery Date: ${date}`,
        `Shipping Address: ${orderData.address}`,
        `Order ID: ${orderId}`,
        `Quantity: ${orderData.quantity}`,
        `Price: $${orderData.productPrice}`
      ].join('\n');      res.json({
        fulfillmentText: `Here are the details of your order:\n${details}`,
        outputContexts: [
          // Maintain user context with buyer ID
          createContext('user-context', 5, {
            buyerId: effectiveBuyerId,
            lastAction: 'getOrderDetails'
          })
        ]
      });
    } catch (error) {
      console.error('GetOrderDetails intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while retrieving the order details.'
      });
    }  } else if (intent === 'UpdateOrderAddress') {
    try {
      console.log('Processing UpdateOrderAddress intent');
      console.log('Parameters:', parameters);

      // Get effective buyer ID from context if available
      const contextBuyerId = userContext?.parameters?.buyerId || userContext?.parameters?.userIdentifier;
      const effectiveBuyerId = contextBuyerId || buyerId;
      
      if (!effectiveBuyerId || effectiveBuyerId === 'anonymous') {
        return res.json({
          fulfillmentText: 'Please sign in to update your order address.',
          outputContexts: [createContext('user_signin_needed', 2, {})]
        });
      }
      
      if (!orderId) {
        // This is the initial intent without orderId
        res.json({
          fulfillmentText: 'Please provide an order ID for which you want to update the address.'
        });
        return;
      }

      const newAddress = parameters.address;
      if (!newAddress) {
        // Trigger follow-up intent for address collection and maintain context
        res.json({
          fulfillmentText: 'Please provide the new address for your order.',
          outputContexts: [
            createContext('user-context', 5, {
              buyerId: effectiveBuyerId,
              orderId: orderId,
              lastAction: 'updateOrderAddress_awaitingAddress'
            })
          ]
        });
        return;
      }

      console.log(`Attempting to update address for order ${orderId} to: ${newAddress}`);      const orderRef = db.collection('orders').doc(orderId);
      const orderDoc = await orderRef.get();
      
      if (!orderDoc.exists) {
        console.log(`Order ${orderId} not found`);
        res.json({
          fulfillmentText: 'Order not found. Please check the order ID and try again.'
        });
        return;
      }

      const orderData = orderDoc.data();
      console.log('Current order data:', orderData);
      
      // Verify that this order belongs to the requesting user
      if (orderData.buyerId !== effectiveBuyerId) {
        console.log(`Order belongs to ${orderData.buyerId}, not ${effectiveBuyerId}`);
        res.json({
          fulfillmentText: 'This order does not belong to your account.'
        });
        return;
      }

      // Only allow address update if order is not accepted yet
      if (orderData.accepted) {
        console.log('Cannot update address: order is already accepted');
        res.json({
          fulfillmentText: 'Sorry, you cannot update the address for orders that have already been accepted.'
        });
        return;
      }

      // Update the address in Firestore
      console.log('Updating address in Firestore...');
      await orderRef.update({
        'address': newAddress
      });      console.log(`Successfully updated address for order ${orderId} to: ${newAddress}`);
      res.json({
        fulfillmentText: `Successfully updated the delivery address for order ${orderId}. New address: ${newAddress}`,
        outputContexts: [
          // Maintain user context with buyer ID
          createContext('user-context', 5, {
            buyerId: effectiveBuyerId,
            lastAction: 'updateOrderAddress_completed'
          })
        ]
      });

    } catch (error) {
      console.error('UpdateOrderAddress intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while updating the order address.'
      });
    }
  } else if (intent === 'UpdateOrderAddress - getAddress') {
    try {
      // This is the follow-up intent that collects the address
      const newAddress = parameters.address;
      if (!newAddress || !orderId) {
        res.json({
          fulfillmentText: 'I need both the order ID and the new address to update your order.'
        });
        return;
      }

      const orderRef = db.collection('orders').doc(orderId);
      await orderRef.update({
        'address': newAddress
      });

      res.json({
        fulfillmentText: `Successfully updated the delivery address for order ${orderId}. New address: ${newAddress}`
      });

    } catch (error) {
      console.error('UpdateOrderAddress - getAddress intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while updating the order address.'
      });
    }  } else if (intent === 'CancelOrder') {
    try {
      console.log('Processing CancelOrder intent');
      console.log('Parameters:', parameters);
      
      // Get effective buyer ID from context if available
      const contextBuyerId = userContext?.parameters?.buyerId || userContext?.parameters?.userIdentifier;
      const effectiveBuyerId = contextBuyerId || buyerId;
      
      if (!effectiveBuyerId || effectiveBuyerId === 'anonymous') {
        return res.json({
          fulfillmentText: 'Please sign in to cancel your order.',
          outputContexts: [createContext('user_signin_needed', 2, {})]
        });
      }
      
      if (!orderId) {
        res.json({
          fulfillmentText: 'Please provide an order ID to cancel. You can say "cancel order ABC123"'
        });
        return;
      }

      console.log(`Attempting to cancel order ${orderId}`);
      const orderRef = db.collection('orders').doc(orderId);
      const orderDoc = await orderRef.get();
      
      if (!orderDoc.exists) {
        console.log(`Order ${orderId} not found`);
        res.json({
          fulfillmentText: 'Order not found. Please check the order ID and try again.'
        });
        return;
      }

      const orderData = orderDoc.data();
      console.log('Current order data:', orderData);
        // Verify that this order belongs to the requesting user
      if (orderData.buyerId !== effectiveBuyerId) {
        console.log(`Order belongs to ${orderData.buyerId}, not ${effectiveBuyerId}`);
        res.json({
          fulfillmentText: 'This order does not belong to your account.'
        });
        return;
      }

      // Only allow cancellation if order is not accepted yet
      if (orderData.accepted) {
        console.log('Cannot cancel: order is already accepted');
        res.json({
          fulfillmentText: 'Sorry, you cannot cancel this order because it has already been accepted by the vendor.'
        });
        return;
      }

      // Delete the order from Firestore
      console.log('Deleting order from Firestore...');
      await orderRef.delete();

      console.log(`Successfully cancelled order ${orderId}`);
      res.json({
        fulfillmentText: `Your order (${orderData.productName}) has been successfully cancelled.`,
        outputContexts: [
          // Maintain user context with buyer ID
          createContext('user-context', 5, {
            buyerId: effectiveBuyerId,
            lastAction: 'cancelOrder'
          })
        ]
      });

    } catch (error) {
      console.error('CancelOrder intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while cancelling the order.'
      });
    }
  } else if (intent === 'GetRecommendations') {
    try {
      if (!buyerId) {
        res.json({
          fulfillmentText: 'To provide personalized recommendations, please sign in to your account.'
        });
        return;
      }

      // Get user's order history
      const ordersSnapshot = await db.collection('orders')
        .where('buyerId', '==', buyerId)
        .orderBy('orderDate', 'desc')
        .get();

      if (ordersSnapshot.empty) {
        res.json({
          fulfillmentText: 'I notice this is your first time with us! Start shopping to get personalized recommendations based on your preferences.'
        });
        return;
      }

      // Analyze orders for patterns
      const vendorStats = {};
      const categoryStats = {};

      for (const doc of ordersSnapshot.docs) {
        const order = doc.data();
        const vendorId = order.vendorId;
        const category = order.category;
        const price = order.productPrice || 0;

        // Track vendor stats
        if (!vendorStats[vendorId]) {
          vendorStats[vendorId] = { count: 0, totalSpent: 0 };
        }
        vendorStats[vendorId].count++;
        vendorStats[vendorId].totalSpent += price;

        // Track category stats
        if (!categoryStats[category]) {
          categoryStats[category] = { count: 0, totalSpent: 0 };
        }
        categoryStats[category].count++;
        categoryStats[category].totalSpent += price;
      }

      // Get top vendor
      let topVendorId = null;
      let maxVendorOrders = 0;
      for (const [vendorId, stats] of Object.entries(vendorStats)) {
        if (stats.count > maxVendorOrders) {
          maxVendorOrders = stats.count;
          topVendorId = vendorId;
        }
      }

      // Get top category
      let topCategory = null;
      let maxCategoryOrders = 0;
      for (const [category, stats] of Object.entries(categoryStats)) {
        if (stats.count > maxCategoryOrders) {
          maxCategoryOrders = stats.count;
          topCategory = category;
        }
      }

      let recommendations = [];

      // Add vendor recommendation
      if (topVendorId) {
        const vendorDoc = await db.collection('vendors').doc(topVendorId).get();
        if (vendorDoc.exists) {
          const vendorData = vendorDoc.data();
          const stats = vendorStats[topVendorId];
          recommendations.push({
            type: 'vendor',
            message: `You've ordered ${stats.count} times from ${vendorData.bussinessName}, spending $${stats.totalSpent.toFixed(2)}. They might have new products you'll love!`,
            button: {
              text: `Visit ${vendorData.bussinessName}'s Store`,
              data: { action: 'openVendor', vendorId: topVendorId }
            }
          });
        }
      }

      // Add category recommendation
      if (topCategory) {
        const stats = categoryStats[topCategory];
        recommendations.push({
          type: 'category',
          message: `You seem to enjoy ${topCategory} products! You've made ${stats.count} purchases in this category.`,
          button: {
            text: `Explore ${topCategory}`,
            data: { action: 'openCategory', category: topCategory }
          }
        });
      }      if (recommendations.length === 0) {
        res.json({
          fulfillmentText: 'I don\'t have enough data to make specific recommendations yet. Keep shopping with us!'
        });
        return;
      }      // Send recommendations one by one with buttons
      let responseIndex = 0;
      const recommendation = recommendations[responseIndex];
      
      // Create context with parameters
      const contextParameters = {
        recommendationType: recommendation.type,
        recommendedVendorId: recommendation.button.data.vendorId || null,
        recommendedCategory: recommendation.button.data.category || null
      };      // Send response with context
      console.log('Sending recommendation:', recommendation);
      console.log('With context parameters:', contextParameters);
      
      res.json({
        fulfillmentText: recommendation.message + 'RECOMMENDATION_BUTTON:' + JSON.stringify(recommendation.button),
        outputContexts: [
          // Recommendation context with parameters
          createContext('recommendation_context', 2, {
            ...contextParameters,
            buyerId: buyerId // Include buyerId in recommendation context
          }),
          // Maintain buyer context with a longer lifespan
          createContext('buyer_context', 5, { 
            buyerId: buyerId,
            lastAction: 'getRecommendations'
          })
        ]
      });

    } catch (error) {
      console.error('GetRecommendations intent error:', error);
      res.json({
        fulfillmentText: 'An error occurred while getting recommendations.'
      });
    }
  } else {
    console.log('Unknown intent:', intent);
    res.json({
      fulfillmentText: 'How can I help you?'
    });
  }
});

app.post('/dialogflow', async (req, res) => {
  try {
    // Handle legacy dialogflow requests if needed
    res.status(200).json({
      fulfillmentText: 'Please use the /webhook endpoint for Dialogflow requests.'
    });
  } catch (error) {
    console.error('Dialogflow webhook error:', error);
    res.status(500).json({
      fulfillmentText: 'An error occurred while processing your request.'
    });
  }
});

app.listen(3000, () => console.log('Fulfillment server running on port 3000'));