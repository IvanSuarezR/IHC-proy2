import fs from 'fs';
import path from 'path';
import express from 'express';
import { Telegraf } from 'telegraf';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const bot = new Telegraf('8383177592:AAEaU7I3Du_YfLNr11vsXAoppYivAvwE-vA');
const app = express();
app.use(express.json());

// Cuando el usuario escribe /start
bot.start(async (ctx) => {
  try {
    // 1️⃣ Enviar la imagen de bienvenida
    const imagePath = path.resolve(__dirname, '../src/images/kingLogo.jpg');
    await ctx.telegram.sendPhoto(
      ctx.chat.id,
      { source: fs.createReadStream(imagePath) },
      {
        caption: '👋 ¡Bienvenido a KingsFoods!\n\n🍔 Descubre nuestras deliciosas hamburguesas al vapor.',
        parse_mode: 'HTML'
      }
    );

    // 2️⃣ Enviar el botón de la miniapp (WebApp)
    await ctx.reply('¡Abre nuestro menú interactivo!', {
      reply_markup: {
        inline_keyboard: [[
          {
            text: '🍔 Abrir menú',
            web_app: { url: 'https://conductor-frontend-608918105626.us-central1.run.app/' }
            // web_app: { url: 'https://chattable-hermine-nonperfectible.ngrok-free.dev/' }
          }
        ]]
      }
    });
  } catch (err) {
    console.error('Error en /start:', err);
  }
});

// Endpoint para enviar confirmación de pedido
app.post('/send-order-confirmation', async (req, res) => {
  try {
    const { telegram_id, pedido_id, productos, total, direccion, estado } = req.body;

    if (!telegram_id) {
      return res.status(400).json({ error: 'telegram_id es requerido' });
    }

    // Crear el mensaje de confirmación
    let mensaje = `✅ *¡Pedido Confirmado!*\n\n`;
    mensaje += `📦 *Pedido #${pedido_id}*\n`;
    mensaje += `━━━━━━━━━━━━━━━━\n\n`;
    
    // Listar productos
    if (productos && productos.length > 0) {
      mensaje += `🍔 *Productos:*\n`;
      productos.forEach(prod => {
        mensaje += `   • ${prod.nombre} x${prod.cantidad} - Bs. ${(prod.precio * prod.cantidad).toFixed(2)}\n`;
      });
      mensaje += `\n`;
    }

    mensaje += `💰 *Total: Bs. ${parseFloat(total).toFixed(2)}*\n\n`;
    mensaje += `📍 *Dirección:* ${direccion}\n\n`;
    mensaje += `🚚 *Estado:* ${estado || 'Pendiente'}\n\n`;
    mensaje += `¡Gracias por tu compra! Tu pedido está siendo procesado. 🎉`;

    // Enviar mensaje al usuario
    await bot.telegram.sendMessage(telegram_id, mensaje, { parse_mode: 'Markdown' });

    res.json({ success: true, message: 'Confirmación enviada' });
  } catch (error) {
    console.error('Error enviando confirmación:', error);
    res.status(500).json({ error: 'Error al enviar confirmación', details: error.message });
  }
});

// Endpoint para actualizar estado del pedido
app.post('/send-order-update', async (req, res) => {
  try {
    const { telegram_id, pedido_id, estado, mensaje_extra } = req.body;

    if (!telegram_id) {
      return res.status(400).json({ error: 'telegram_id es requerido' });
    }

    const estadosEmoji = {
      'pendiente': '⏳',
      'buscando': '🔍',
      'aceptado': '✅',
      'recibido': '🚚',
      'entregado': '🎉',
      'cancelado': '❌',
      'disponible': '📢'
    };

    const emoji = estadosEmoji[estado] || '📦';
    let mensaje = `${emoji} *Actualización de Pedido #${pedido_id}*\n\n`;
    mensaje += `*Estado:* ${estado}\n`;
    
    if (mensaje_extra) {
      mensaje += `\n${mensaje_extra}`;
    }

    await bot.telegram.sendMessage(telegram_id, mensaje, { parse_mode: 'Markdown' });

    res.json({ success: true, message: 'Actualización enviada' });
  } catch (error) {
    console.error('Error enviando actualización:', error);
    res.status(500).json({ error: 'Error al enviar actualización', details: error.message });
  }
});

// Captura datos enviados desde la WebApp
bot.on('message', (ctx) => {
  if (ctx.message.web_app_data) {
    const data = JSON.parse(ctx.message.web_app_data.data);
    console.log('📦 Datos recibidos desde la WebApp:', data);
    ctx.reply(`✅ Pedido recibido: ${data.item} - $${data.price}`);
  }
});

// Inicia el bot
bot.launch();
console.log('🤖 Bot funcionando...');

// Inicia el servidor HTTP para recibir notificaciones
const PORT = process.env.BOT_PORT || 3001;
app.listen(PORT, () => {
  console.log(`🌐 Servidor HTTP del bot escuchando en puerto ${PORT}`);
});
