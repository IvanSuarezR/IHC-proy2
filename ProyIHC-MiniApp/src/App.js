// src/App.js
import { useState } from "react";
import "./App.css";
import MenuPrincipal from "./views/MenuPrincipal.jsx";
import CarritoView from "./views/CarritoView.jsx";
import EnvioView from "./views/EnvioView.jsx";
import PagoView from "./views/PagoView.jsx";
import ConfirmacionView from "./views/ConfirmacionView.jsx";
import HistorialView from "./views/HistorialView.jsx";

function App() {
  const [currentView, setCurrentView] = useState("menu");
  const [cartItems, setCartItems] = useState([]);
  const [direccion, setDireccion] = useState(""); // Estado para la dirección

  const navigate = (view) => setCurrentView(view);

  const reiniciarPedido = () => {
    setCartItems([]);
    setDireccion("");
    // Si guardaste teléfono o coordenadas en sessionStorage:
    sessionStorage.removeItem("user_phone_number");
    sessionStorage.removeItem("pedido_lat");
    sessionStorage.removeItem("pedido_lng");
  };

  return (
    <>
      {/* Vista de menu principal */}
      {currentView === "menu" && (
        <MenuPrincipal
          cartItems={cartItems}
          setCartItems={setCartItems}
          navigate={navigate}
        />
      )}
      {/* Llama a la vista de Carrito */}
      {currentView === "carrito" && (
        <CarritoView
          cartItems={cartItems}
          setCartItems={setCartItems}
          navigate={navigate}
        />
      )}
      {/* Vista de envio */}
      {currentView === "envio" && (
        <EnvioView
          cartItems={cartItems}
          navigate={navigate}
          direccion={direccion}
          setDireccion={setDireccion}
        />
      )}
      {currentView === "pago" && (
        <PagoView
          cartItems={cartItems}
          navigate={navigate}
        />
      )}
      {/* Vista de confirmacion de compras */}
      {currentView === "confirmacion" && (
        <ConfirmacionView
          cartItems={cartItems}
          navigate={(view) => {
            if (view === "menu") reiniciarPedido();
            setCurrentView(view);
          }}
          direccion={direccion}
        />
      )}
      {/* Vista de historial de pedidos */}
      {currentView === "historial" && (
        <HistorialView
          cartItems={cartItems}
          navigate={navigate}
        />
      )}
    </>
  );
}

export default App;
