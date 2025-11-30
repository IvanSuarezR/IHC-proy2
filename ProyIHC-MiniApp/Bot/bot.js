import fs from 'fs';
import path from 'path';
import { Telegraf } from 'telegraf';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const bot = new Telegraf('8383177592:AAEaU7I3Du_YfLNr11vsXAoppYivAvwE-vA');

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
          }
        ]]
      }
    });
  } catch (err) {
    console.error('Error en /start:', err);
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
