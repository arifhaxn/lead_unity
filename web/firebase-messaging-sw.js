importScripts("https://www.gstatic.com/firebasejs/10.4.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.4.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCsKKIdMZjS4-7fxzrUMIgkRekrLZYTbFY",
  authDomain: "leadunity-68950.firebaseapp.com",
  projectId: "leadunity-68950",
  storageBucket: "leadunity-68950.firebasestorage.app",
  messagingSenderId: "69294984603",
  appId: "1:69294984603:web:56f344481f3273a7e5653e",
});

const messaging = firebase.messaging();

// Fires when a push arrives and no tab has focus.
//
// Payloads that carry a `notification` block are drawn by the browser itself,
// so this handler only needs to render data-only messages — otherwise the user
// would see the same notification twice.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;

  const data = payload.data || {};
  self.registration.showNotification(data.title || "LeadUnity", {
    body: data.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    tag: data.proposalId || "leadunity-general",
    data: data,
  });
});

// Focus an existing tab if one is open, otherwise open a new one.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ("focus" in client) return client.focus();
        }
        if (clients.openWindow) return clients.openWindow("/");
      })
  );
});