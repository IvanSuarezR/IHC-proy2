// src/App.js
import { useState } from "react";
import "./App.css";
import MenuPrincipal from "./views/MenuPrincipal.jsx";
import CarritoView from "./views/CarritoView.jsx";
import EnvioView from "./views/EnvioView.jsx";
import PagoView from "./views/PagoView.jsx";
import ConfirmacionView from "./views/ConfirmacionView.jsx";
function App() {
  const [currentView, setCurrentView] = useState("menu");
  const [cartItems, setCartItems] = useState([]);
  const [direccion, setDireccion] = useState(""); // Estado para la dirección

  const navigate = (view) => setCurrentView(view);

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
          navigate={navigate}
          direccion={direccion}
        />
      )}
    </>
  );
}

export default App;
