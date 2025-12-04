import React, { useState, useEffect } from "react";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";
import "./EnvioView.css";
import Modal from "../Components/Modal/Modal";
import kingLogo from "../images/kingLogo.jpg";
import Header from "../Components/Header/Header.jsx";


const MapComponent = ({ onLocationSelect, onClose }) => {
  const [markerPosition, setMarkerPosition] = useState(null);
  const [center, setCenter] = useState({ lat: -17.783294, lng: -63.182128 });

  const { isLoaded } = useJsApiLoader({
    id: "google-map-script",
    googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_KEY,
  });

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setCenter({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          });
        },
        () => {}
      );
    }
  }, []);

  const mapContainerStyle = {
    width: "100%",
    height: "80%",
  };

  const onMapClick = (e) => {
    setMarkerPosition({
      lat: e.latLng.lat(),
      lng: e.latLng.lng(),
    });
  };

  const handleConfirmLocation = async () => {
    if (!markerPosition) {
      alert("Por favor, selecciona una ubicación en el mapa.");
      return;
    }

    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${markerPosition.lat}&lon=${markerPosition.lng}`
      );
      const data = await response.json();

      const address =
        data.display_name ||
        `${markerPosition.lat}, ${markerPosition.lng}`;

      onLocationSelect({
        address,
        lat: markerPosition.lat,
        lng: markerPosition.lng,
      });
    } catch (error) {
      console.error("Error obteniendo dirección:", error);
      onLocationSelect({
        address: `${markerPosition.lat}, ${markerPosition.lng}`,
        lat: markerPosition.lat,
        lng: markerPosition.lng,
      });
    }
  };

  if (!isLoaded) return <div>Cargando...</div>;

  return (
    <div className="map-modal">
      <div className="map-container">
        <GoogleMap
          mapContainerStyle={mapContainerStyle}
          zoom={15}
          center={center}
          onClick={onMapClick}
          options={{ gestureHandling: "greedy" }}
        >
          {markerPosition && <Marker position={markerPosition} />}
        </GoogleMap>

        <button
          className="btn-confirmar-ubicacion"
          onClick={handleConfirmLocation}
        >
          Seleccionar Ubicación
        </button>

        <button className="btn-cerrar-mapa" onClick={onClose}>
          X
        </button>
      </div>
    </div>
  );
};

function EnvioView({ cartItems, navigate, direccion, setDireccion }) {
  const [showMap, setShowMap] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );

  const delivery = 2;
  const discount = subtotal * 0.002;
  const total = subtotal + delivery - discount;

  const handleLocationSelect = (locationData) => {
    setDireccion(locationData.address);
    sessionStorage.setItem("pedido_lat", locationData.lat);
    sessionStorage.setItem("pedido_lng", locationData.lng);
    setShowMap(false);
  };

  return (
    <div className="envio-container">

     <Header
        title="Orden de Envio"
        cartItems={cartItems}
        navigate={navigate}
        showCart={false}
        showBack={true}
        onBack={() => navigate("carrito")}
      />


      {/* MAPA */}
      {showMap && (
        <MapComponent
          onLocationSelect={handleLocationSelect}
          onClose={() => setShowMap(false)}
        />
      )}

      {/* CONTENIDO */}
      <div className="envio-content-new">

        {/* LISTA DE PRODUCTOS */}
        <div className="envio-card-new">
          <h2 className="envio-section-title-new">Tu Pedido</h2>
          {cartItems.map((item) => (
            <div className="envio-item-new" key={item.id}>
              <span>{item.title} x {item.quantity}</span>
              <span>Bs. {(item.price * item.quantity).toFixed(2)}</span>
            </div>
          ))}
        </div>

        {/* RESUMEN */}
        <div className="envio-card-new">
          <h2 className="envio-section-title-new">Resumen</h2>
          <div className="envio-row-new">
            <span>Delivery</span>
            <span>Bs. {delivery}</span>
          </div>
          <div className="envio-row-new">
            <span>Descuento</span>
            <span>- Bs. {discount.toFixed(2)}</span>
          </div>
          <div className="envio-total-row-new">
            <strong>Total</strong>
            <strong className="envio-total-amount-new">
              Bs. {total.toFixed(2)}
            </strong>
          </div>
        </div>

        {/* DIRECCIÓN */}
        <div className="envio-card-new">
          <h2 className="envio-section-title-new">Dirección de Envío</h2>

          <button
            className="envio-btn-mapa-new"
            onClick={() => setShowMap(true)}
          >
            🌍 Seleccionar ubicación en el mapa
          </button>

          <input
            type="text"
            placeholder="Tu ubicación seleccionada aparecerá aquí"
            value={direccion}
            readOnly
            className="envio-input-new"
          />
        </div>

        {/* BOTONES */}
        <div className="envio-buttons-new">
          <button
            className="btn-back-new"
            onClick={() => navigate("carrito")}
          >
            Volver
          </button>

          <button
            className="btn-pago-new"
            onClick={() => {
              if (!direccion || direccion.trim() === "") {
                setErrorMessage(
                  "Por favor selecciona una ubicación en el mapa antes de continuar."
                );
                return;
              }
              navigate("pago");
            }}
          >
            💳 Finalizar pedido
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

export default EnvioView;
