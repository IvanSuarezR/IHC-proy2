import fs from 'fs';
import path from 'path';
import { Telegraf } from 'telegraf';

const bot = new Telegraf('TU_TOKEN_DEL_BOT');

bot.start(async (ctx) => {
  // Ruta de la imagen
  const imagePath = path.resolve('../src/images/kingLogo.jpg');

  // Enviar la "presentación" completa
  await ctx.telegram.sendPhoto(ctx.chat.id, { source: fs.createReadStream(imagePath) }, {
    caption: `
👋 ¡Bienvenido a KingsFoods!

🍔 Descubre nuestras deliciosas hamburguesas al vapor.
📦 Ordena fácil desde nuestra WebApp.
    `,
    parse_mode: 'HTML', // si quieres texto enriquecido
    reply_markup: {
      inline_keyboard: [
        [
          {
            text: '🍔 Abrir menú',
            web_app: { url: 'https://chattable-hermine-nonperfectible.ngrok-free.dev/' }
          }
        ],
        [
          {
            text: '📞 Contacto',
            url: 'https://t.me/TuContactoBot' // opcional, link directo
          }
        ]
      ]
    }
  });
});

bot.launch();
console.log('🤖 Bot funcionando...');
