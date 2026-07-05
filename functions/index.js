const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { userId, title, message, targetId, senderId, type } = data;

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const payload = {
      notification: {
        title: title || 'إشعار جديد',
        body: message || '',
      },
      data: {
        targetId: targetId || '',
        senderId: senderId || '',
        type: type || '',
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(payload);
    } catch (error) {
      if (error.code === 'messaging/registration-token-not-registered') {
        await admin.firestore().collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }
    }
  });

exports.sendNotificationToAdmins = functions.firestore
  .document('properties/{propertyId}')
  .onCreate(async (snap, context) => {
    const property = snap.data();
    const title = property?.title || 'عقار جديد';

    const usersSnapshot = await admin.firestore().collection('users').get();
    const admins = usersSnapshot.docs.filter(doc => {
      const role = doc.data().role || '';
      return role === 'admin';
    });

    const notifications = admins.map(adminDoc => {
      const fcmToken = adminDoc.data().fcmToken;
      if (!fcmToken) return null;

      return admin.messaging().send({
        notification: {
          title: 'عقار جديد',
          body: `تم إضافة عقار جديد: ${title}`,
        },
        data: {
          targetId: context.params.propertyId,
          type: 'property',
        },
        token: fcmToken,
      }).catch(error => {
        if (error.code === 'messaging/registration-token-not-registered') {
          return admin.firestore().collection('users').doc(adminDoc.id).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        }
      });
    });

    await Promise.all(notifications);
  });

exports.sendNotificationOnMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const senderId = message?.senderId || '';
    const messageText = message?.message || '';

    const convDoc = await admin.firestore()
      .collection('conversations').doc(context.params.conversationId).get();
    if (!convDoc.exists) return;

    const convData = convDoc.data();
    const ownerId = convData.ownerId;
    const interestedUserId = convData.interestedUserId;
    const recipientId = senderId === ownerId ? interestedUserId : ownerId;

    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.exists ? (senderDoc.data().fullName || 'مستخدم') : 'مستخدم';

    await admin.messaging().send({
      notification: {
        title: `رسالة من ${senderName}`,
        body: messageText,
      },
      data: {
        conversationId: context.params.conversationId,
        senderId: senderId,
        type: 'message',
      },
      token: fcmToken,
    }).catch(async error => {
      if (error.code === 'messaging/registration-token-not-registered') {
        await admin.firestore().collection('users').doc(recipientId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }
    });
  });
