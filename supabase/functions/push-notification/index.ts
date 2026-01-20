import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { create } from 'https://deno.land/x/djwt@v3.0.1/mod.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// Environment variables
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

interface NotificationPayload {
  receiver_id: string
  type: 'like' | 'comment' | 'follow'
  message: string
  sender_id?: string
  post_id?: string
}

interface FCMResponse {
  name?: string
  error?: {
    code: number
    message: string
    status: string
  }
}

async function getFirebaseAccessToken(): Promise<string> {
  const privateKey = FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')

  const pemHeader = '-----BEGIN PRIVATE KEY-----'
  const pemFooter = '-----END PRIVATE KEY-----'
  const pemContents = privateKey
      .replace(pemHeader, '')
      .replace(pemFooter, '')
      .replace(/\s/g, '')

  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      binaryDer,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign']
  )

  const now = Math.floor(Date.now() / 1000)
  const jwt = await create(
      { alg: 'RS256', typ: 'JWT' },
      {
        iss: FIREBASE_CLIENT_EMAIL,
        sub: FIREBASE_CLIENT_EMAIL,
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
      },
      cryptoKey
  )

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${await tokenResponse.text()}`)
  }

  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

async function sendFCMNotification(
    fcmToken: string,
    payload: NotificationPayload,
    accessToken: string
): Promise<FCMResponse> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`

  const response = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: {
          title: getNotificationTitle(payload.type),
          body: payload.message,
        },
        data: {
          type: payload.type,
          sender_id: payload.sender_id || '',
          post_id: payload.post_id || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'yet_connect_high_importance',
            sound: 'default',
          },
        },
        apns: {
          headers: { 'apns-priority': '10' },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    }),
  })

  return await response.json()
}

function getNotificationTitle(type: string): string {
  const titles: Record<string, string> = {
    like: '❤️ Yeni Beğeni',
    comment: '💬 Yeni Yorum',
    follow: '👤 Yeni Takipçi',
  }
  return titles[type] || '🔔 Bildirim'
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: NotificationPayload = await req.json()

    console.log(`📨 Notification: ${payload.type} for ${payload.receiver_id}`)

    if (!payload.receiver_id || !payload.type || !payload.message) {
      return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', payload.receiver_id)
        .single()

    if (profileError || !profile?.fcm_token) {
      console.log(`⚠️ No FCM token for user: ${payload.receiver_id}`)
      return new Response(
          JSON.stringify({ error: 'No FCM token found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`🔑 Getting Firebase access token...`)
    const accessToken = await getFirebaseAccessToken()

    console.log(`📤 Sending FCM notification...`)
    const fcmResult = await sendFCMNotification(profile.fcm_token, payload, accessToken)

    if (fcmResult.error) {
      console.error(`❌ FCM error:`, fcmResult.error)
      return new Response(
          JSON.stringify({ error: fcmResult.error }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Notification sent: ${fcmResult.name}`)

    return new Response(
        JSON.stringify({ success: true, message_id: fcmResult.name }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error(`❌ Error:`, error)
    return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
