// src/views/ConfirmacionView.jsx
import React, { useEffect, useState } from "react";
import "./ConfirmacionView.css";
import kingLogo from "../images/kingLogo.jpg";

function ConfirmacionView({ cartItems, navigate, direccion }) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [pedidoEnviado, setPedidoEnviado] = useState(false);

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );
  const delivery = 2;
  const discount = subtotal * 0.002;
  const total = subtotal + delivery - discount;

  useEffect(() => {
    const crearPedido = async () => {
      if (pedidoEnviado) return;
      setPedidoEnviado(true);

      try {
        const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
        const telegramId = tgUser?.id || "123456789";
        
        // Recuperar telefono si se guardó en PagoView
        const phoneNumber = sessionStorage.getItem('user_phone_number');
        
        // Recuperar coordenadas de sessionStorage
        const lat = sessionStorage.getItem('pedido_lat');
        const lng = sessionStorage.getItem('pedido_lng');
        const coordenadas = lat && lng ? `${lat},${lng}` : null;

        const pedido = {
          telegram_id: telegramId,
          first_name: tgUser?.first_name || "Cliente",
          username: tgUser?.username || "",
          phone_number: phoneNumber || "",
          direccion: direccion,
          coordenadas: coordenadas,
          total: total.toFixed(2),
          productos: cartItems.map((item) => ({
            producto_id: item.id,
            nombre: item.title,
            cantidad: item.quantity,
            precio: item.price,
          })),
        };

        const apiUrl = process.env.REACT_APP_API_URL || "http://127.0.0.1:8000";
        const response = await fetch(`${apiUrl}/api/pedidos/`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(pedido),
        });

        if (!response.ok) {
          throw new Error("Error al crear el pedido");
        }

        setLoading(false);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    };

    crearPedido();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (loading) {
    return (
      <div className="confirm-container">
        <h2>Procesando tu pedido...</h2>
      </div>
    );
  }

  if (error) {
    return (
      <div className="confirm-container">
        <h2>Error</h2>
        <p>{error}</p>
        <button className="btn-volver-menu" onClick={() => navigate("menu")}>
          🔙 Volver al menú
        </button>
      </div>
    );
  }

  return (
    <div className="confirm-container">
      <div className="confirm-icon">✔</div>
      <div className="confirm-image-space">
        <img src={kingLogo} alt="King Logo" className="logo" />
      </div>
      <h2 className="confirm-title">Pedido Confirmado</h2>
      <div className="confirm-details">
        <p><strong>Descripción del pedido:</strong></p>
        {cartItems.map((item) => (
          <p key={item.id}>
            • {item.title} x {item.quantity} — ${item.price * item.quantity}
          </p>
        ))}
        <p><strong>Total del pedido:</strong> ${total.toFixed(2)}</p>
        <p><strong>Estado:</strong> Pagado ✅</p>
      </div>
      <h3 className="confirm-status">🚚 PEDIDO EN CAMINO</h3>
      <p className="confirm-thanks">¡Gracias por su compra! 🙌</p>
      <button className="btn-volver-menu" onClick={() => navigate("menu")}>
        🔙 Volver al menú
      </button>
    </div>
  );
}

export default ConfirmacionView;
