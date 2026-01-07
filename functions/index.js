const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onChatMessageCreate = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const receiverId = messageData.receiverId;
        const senderId = messageData.senderId;
        const text = messageData.text || "Sent you a message";

        try {
            // Fetch receiver's FCM token
            const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
            const fcmToken = receiverDoc.data()?.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token found for user ${receiverId}`);
                return null;
            }

            // Fetch sender's name
            const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
            const senderName = senderDoc.data()?.name || "Someone";
            const senderProfileImage = senderDoc.data()?.profileImage || "";

            // Construct notification message
            const message = {
                token: fcmToken,
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    chatId: context.params.chatId,
                    senderId: senderId,
                    senderName: senderName,
                    senderProfileImage: senderProfileImage,
                    type: "chat_message",
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "high_importance_channel",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            // Send FCM message
            const response = await admin.messaging().send(message);
            console.log("Successfully sent message:", response);
            return response;
        } catch (error) {
            console.error("Error sending message:", error);
            return null;
        }
    });
