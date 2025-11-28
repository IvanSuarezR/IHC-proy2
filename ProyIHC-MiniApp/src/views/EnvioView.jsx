// src/views/EnvioView.jsx
import React, { useState, useEffect } from "react";
import {
  GoogleMap,
  useJsApiLoader,
  Marker,
} from "@react-google-maps/api";
import "./EnvioView.css";

const MapComponent = ({ onLocationSelect, onClose }) => {
  const [markerPosition, setMarkerPosition] = useState(null);
  const [center, setCenter] = useState({ lat: -17.783294, lng: -63.182128});


  const { isLoaded } = useJsApiLoader({
    id: "google-map-script",
    googleMapsApiKey: "AIzaSyCpb8QkvuIvYhgxfidC6O6IMKgyK0fj560",
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
        () => {
          // No se pudo obtener la ubicación, se mantiene el centro por defecto
        }
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

  const handleConfirmLocation = () => {
    if (markerPosition) {
      onLocationSelect(`${markerPosition.lat}, ${markerPosition.lng}`);
    } else {
      alert("Por favor, selecciona una ubicación en el mapa.");
    }
  };

  if (!isLoaded) {
    return <div>Cargando...</div>;
  }

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

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );
  const delivery = 2;
  const discount = subtotal * 0.002;
  const total = subtotal + delivery - discount;

  const handleLocationSelect = (coords) => {
    setDireccion(coords);
    setShowMap(false);
  };

  return (
    <div className="envio-container">
      {showMap && (
        <MapComponent
          onLocationSelect={handleLocationSelect}
          onClose={() => setShowMap(false)}
        />
      )}
      <h2>Detalles del Envío</h2>

      {/* Lista de productos */}
      <div className="envio-list">
        {cartItems.map((item) => (
          <div className="envio-item" key={item.id}>
            <span>
              {item.title} ({item.quantity})
            </span>
            <span>${(item.price * item.quantity).toFixed(2)}</span>
          </div>
        ))}
      </div>

      {/* Resumen */}
      <div className="envio-summary">
        <p>Delivery: ${delivery}</p>
        <p>Descuento: -${discount.toFixed(2)}</p>
        <h3>Total: ${total.toFixed(2)}</h3>
      </div>

      {/* Dirección */}
      <div className="envio-direccion">
        <p>📍 Dirección de envío:</p>
        
        <button className="btn-ubicacion" onClick={() => setShowMap(true)}>
          🌍 Seleccionar mi ubicación en el mapa
        </button>

        <input
          type="text"
          placeholder="Tu ubicación seleccionada aparecerá aquí"
          value={direccion}
          readOnly
        />
      </div>

      {/* Botones inferiores */}
      <div className="envio-buttons">
        <button className="btn-volver" onClick={() => navigate("carrito")}>
          🔙 Volver
        </button>

        <button className="btn-pago" onClick={() => navigate("pago")}>
          💳 Finalizar pedido
        </button>
      </div>
    </div>
  );
}

export default EnvioView;
