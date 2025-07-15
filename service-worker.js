// Service Worker para Gestor PRO+
// Versão: 2.0.0

const CACHE_NAME = 'gestor-proplus-v2.0.0'
const CACHE_ASSETS = [
  '/',
  '/index.html',
  '/src/main.js',
  '/src/ui/styles/main.css',
  '/manifest.json',
  '/icon-192x192.png',
  '/icon-512x512.png'
]

// Instalação do Service Worker
self.addEventListener('install', event => {
  console.log('Service Worker: Instalando...')
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Service Worker: Cacheando arquivos')
        return cache.addAll(CACHE_ASSETS)
      })
      .then(() => self.skipWaiting())
  )
})

// Ativação do Service Worker
self.addEventListener('activate', event => {
  console.log('Service Worker: Ativando...')
  
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cache => {
          if (cache !== CACHE_NAME) {
            console.log('Service Worker: Removendo cache antigo')
            return caches.delete(cache)
          }
        })
      )
    })
  )
})

// Interceptação de requisições
self.addEventListener('fetch', event => {
  if (event.request.url.includes('/rest/v1/')) {
    // Estratégia stale-while-revalidate para API do Supabase
    event.respondWith(
      caches.open(CACHE_NAME)
        .then(cache => {
          return cache.match(event.request)
            .then(response => {
              if (response) {
                // Tentar atualizar em background
                fetch(event.request)
                  .then(fetchResponse => {
                    cache.put(event.request, fetchResponse.clone())
                  })
                  .catch(() => {})
                
                return response
              }
              
              // Se não está em cache, buscar da rede
              return fetch(event.request)
                .then(fetchResponse => {
                  cache.put(event.request, fetchResponse.clone())
                  return fetchResponse
                })
                .catch(() => {
                  // Se offline, retornar resposta padrão
                  return new Response(JSON.stringify({
                    error: 'Offline',
                    message: 'Sem conexão com a internet'
                  }), {
                    status: 503,
                    headers: { 'Content-Type': 'application/json' }
                  })
                })
            })
        })
    )
  } else {
    // Estratégia cache-first para outros recursos
    event.respondWith(
      caches.match(event.request)
        .then(response => {
          return response || fetch(event.request)
        })
        .catch(() => {
          // Se offline e é uma navegação, retornar página principal
          if (event.request.mode === 'navigate') {
            return caches.match('/index.html')
          }
        })
    )
  }
})

// Background Sync para sincronização offline
self.addEventListener('sync', event => {
  if (event.tag === 'sync-orcamentos') {
    event.waitUntil(syncOrcamentos())
  }
})

async function syncOrcamentos() {
  try {
    console.log('Service Worker: Sincronizando orçamentos...')
    
    // Buscar dados da IndexedDB
    const db = await openDB()
    const transaction = db.transaction(['sync_queue'], 'readonly')
    const store = transaction.objectStore('sync_queue')
    const pendingSync = await store.getAll()
    
    // Sincronizar cada item
    for (const item of pendingSync) {
      try {
        await syncItem(item)
        // Remover da queue após sincronização
        await removeFromQueue(item.id)
      } catch (error) {
        console.error('Erro ao sincronizar item:', error)
      }
    }
    
    console.log('Service Worker: Sincronização concluída')
  } catch (error) {
    console.error('Erro na sincronização:', error)
  }
}

async function syncItem(item) {
  const response = await fetch(`https://uymunsavnpfcsuznrugi.supabase.co/rest/v1/${item.table_name}`, {
    method: item.operation === 'create' ? 'POST' : 
           item.operation === 'update' ? 'PATCH' : 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${item.token}`,
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5bXVuc2F2bnBmY3N1em5ydWdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3ODU3ODgsImV4cCI6MjA2NjM2MTc4OH0.Kz__-jB9SsD-w7SuwlYCWPuEOcOX9epRE9CB5jd4eFY'
    },
    body: JSON.stringify(item.data)
  })
  
  if (!response.ok) {
    throw new Error(`Erro na sincronização: ${response.status}`)
  }
}

function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('GestorProPlusDB', 1)
    
    request.onerror = () => reject(request.error)
    request.onsuccess = () => resolve(request.result)
  })
}

async function removeFromQueue(id) {
  const db = await openDB()
  const transaction = db.transaction(['sync_queue'], 'readwrite')
  const store = transaction.objectStore('sync_queue')
  await store.delete(id)
}

// Push Notifications (para futura implementação)
self.addEventListener('push', event => {
  if (event.data) {
    const data = event.data.json()
    
    const options = {
      body: data.message,
      icon: '/icon-192x192.png',
      badge: '/icon-192x192.png',
      vibrate: [100, 50, 100],
      data: {
        dateOfArrival: Date.now(),
        primaryKey: data.id
      }
    }
    
    event.waitUntil(
      self.registration.showNotification(data.title, options)
    )
  }
})

// Clique em notificações
self.addEventListener('notificationclick', event => {
  console.log('Notificação clicada:', event.notification.tag)
  
  event.notification.close()
  
  event.waitUntil(
    clients.openWindow('/')
  )
})