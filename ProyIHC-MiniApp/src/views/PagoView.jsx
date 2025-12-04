// src/views/PagoView.jsx
import React, { useState } from "react";
import "./PagoView.css";
import Modal from "../Components/Modal/Modal.jsx";
import Header from "../Components/Header/Header.jsx";

function PagoView({ cartItems, navigate }) {
  const [metodo, setMetodo] = useState("efectivo");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [errorMessage, setErrorMessage] = useState(null);

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );

  const delivery = 2;
  const discount = subtotal * 0.002;
  const total = subtotal + delivery - discount;

  return (
    <div className="pago-container">

      {/* HEADER GLOBAL */}
      <Header
        title="Método de Pago"
        navigate={navigate}
        cartItems={cartItems}
        showCart={false}
        showBack={true}
        onBack={() => navigate("envio")}
      />

      {/* CONTENIDO */}
      <div className="pago-content-new">

        {/* RESUMEN DEL PEDIDO */}
        <div className="pago-card-new">
          <h2 className="pago-section-title-new">Tu Pedido</h2>

          {cartItems.map((item) => (
            <div className="pago-item-new" key={item.id}>
              <span>{item.title} x {item.quantity}</span>
              <span>Bs. {(item.price * item.quantity).toFixed(2)}</span>
            </div>
          ))}

          <div className="pago-row-new">
            <span>Delivery</span>
            <span>Bs. {delivery}</span>
          </div>

          <div className="pago-row-new">
            <span>Descuento</span>
            <span>- Bs. {discount.toFixed(2)}</span>
          </div>

          <div className="pago-total-row-new">
            <strong>Total</strong>
            <strong>Bs. {total.toFixed(2)}</strong>
          </div>
        </div>

        {/* TELÉFONO */}
        <div className="pago-card-new">
          <h2 className="pago-section-title-new">Número de Contacto</h2>

          <input
            type="tel"
            placeholder="Ej: 77777777"
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
            className="pago-input-new"
          />
        </div>

        {/* MÉTODOS DE PAGO */}
        <div className="pago-card-new">
          <h2 className="pago-section-title-new">Selecciona un método</h2>

          <label className="pago-radio-item">
            <input
              type="radio"
              name="metodo"
              value="efectivo"
              checked={metodo === "efectivo"}
              onChange={(e) => setMetodo(e.target.value)}
            />
            💵 Pago en efectivo
          </label>

          <label className="pago-radio-item">
            <input
              type="radio"
              name="metodo"
              value="qr"
              checked={metodo === "qr"}
              onChange={(e) => setMetodo(e.target.value)}
            />
            📱 Código QR
          </label>

          <label className="pago-radio-item">
            <input
              type="radio"
              name="metodo"
              value="tarjeta"
              checked={metodo === "tarjeta"}
              onChange={(e) => setMetodo(e.target.value)}
            />
            💳 Tarjeta de débito/crédito
          </label>
        </div>

        {/* BOTONES */}
        <div className="pago-buttons-new">
          <button
            className="btn-volver-new"
            onClick={() => navigate("envio")}
          >
            Atras
          </button>

          <button
            className="btn-confirmar-new"
            onClick={() => {
              if (phoneNumber.trim() === "") {
                setErrorMessage("Ingresa tu número de teléfono para continuar.");
                return;
              }

              sessionStorage.setItem("user_phone_number", phoneNumber);
              sessionStorage.setItem("user_payment_method", metodo);

              navigate("confirmacion");
            }}
          >
            ✅ Confirmar
          </button>
        </div>

      </div>

      <Modal
        message={errorMessage}
        onClose={() => setErrorMessage(null)}
      />
    </div>
  );
}

export default PagoView;
