import React, { useState, useEffect } from "react";
import "./HistorialView.css";
import Header from "../Components/Header/Header.jsx";

function HistorialView({ navigate, cartItems }) {
  const [pedidos, setPedidos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchPedidos = async () => {
      try {
        const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
        const telegramId = tgUser?.id || "123456789";

        const apiUrl = process.env.REACT_APP_API_URL || "http://127.0.0.1:8000";
        const response = await fetch(`${apiUrl}/api/pedidos/?telegram_id=${telegramId}`);

        if (!response.ok) {
          throw new Error("Error al obtener el historial de pedidos");
        }

        const data = await response.json();
        // Ordenar por fecha descendente (más recientes primero)
        const pedidosOrdenados = data.sort((a, b) => 
          new Date(b.created_at) - new Date(a.created_at)
        );
        setPedidos(pedidosOrdenados);
        setLoading(false);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    };

    fetchPedidos();
  }, []);

  const getEstadoColor = (estado) => {
    const colores = {
      'pendiente': '#FFC107',
      'buscando': '#2196f3ff',
      'aceptado': '#4CAF50',
      'recibido': '#9C27B0',
      'entregado': '#4CAF50',
      'cancelado': '#F44336',
      'disponible': '#2196f3ff'
    };
    return colores[estado] || '#757575';
  };

  const getEstadoTexto = (estado) => {
    const textos = {
      'pendiente': 'Pendiente',
      'buscando': 'Buscando Conductor',
      'aceptado': 'Aceptado',
      'recibido': 'En Camino',
      'entregado': 'Entregado ✅',
      'cancelado': 'Cancelado',
      'disponible': 'Buscando Conductor'
    };
    return textos[estado] || estado;
  };

  const formatearFecha = (fecha) => {
    const date = new Date(fecha);
    return date.toLocaleDateString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="historial-container">
        <Header
          title="Historial de Pedidos"
          cartItems={cartItems}
          navigate={navigate}
          showCart={true}
          showBack={true}
          showHistory={false}
          onBack={() => navigate("menu")}
        />
        <div className="historial-loading">
          <p>Cargando historial...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="historial-container">
        <Header
          title="Historial de Pedidos"
          cartItems={cartItems}
          navigate={navigate}
          showCart={true}
          showBack={true}
          showHistory={false}
          onBack={() => navigate("menu")}
        />
        <div className="historial-error">
          <p>❌ {error}</p>
          <button onClick={() => navigate("menu")}>Volver al menú</button>
        </div>
      </div>
    );
  }

  return (
    <div className="historial-container">
      <Header
        title="Historial de Pedidos"
        cartItems={cartItems}
        navigate={navigate}
        showCart={true}
        showBack={true}
        showHistory={false}
        onBack={() => navigate("menu")}
      />

      <div className="historial-content">
        {pedidos.length === 0 ? (
          <div className="historial-empty">
            <p>📦 No tienes pedidos aún</p>
            <button className="btn-menu" onClick={() => navigate("menu")}>
              Ir al menú
            </button>
          </div>
        ) : (
          <div className="historial-lista">
            {pedidos.map((pedido) => (
              <div key={pedido.id} className="historial-card">
                <div className="historial-card-header">
                  <span className="pedido-numero">Pedido #{pedido.id}</span>
                  <span 
                    className="pedido-estado"
                    style={{ backgroundColor: getEstadoColor(pedido.estado) }}
                  >
                    {getEstadoTexto(pedido.estado)}
                  </span>
                </div>

                <div className="historial-card-body">
                  <div className="pedido-info">
                    <span className="info-label">📅 Fecha:</span>
                    <span>{formatearFecha(pedido.created_at)}</span>
                  </div>

                  <div className="pedido-info">
                    <span className="info-label">📍 Dirección:</span>
                    <span className="direccion-text">{pedido.direccion}</span>
                  </div>

                  <div className="pedido-productos">
                    <span className="info-label">🍔 Productos:</span>
                    <ul>
                      {pedido.productos.map((producto, idx) => (
                        <li key={idx}>
                          {producto.nombre} x {producto.cantidad} - Bs. {(producto.precio * producto.cantidad).toFixed(2)}
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div className="pedido-total">
                    <span className="info-label">💰 Total:</span>
                    <span className="total-amount">Bs. {parseFloat(pedido.total).toFixed(2)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default HistorialView;
