import React from "react";
import kingLogo from "../../images/kingLogo.jpg";
import "./Header.css";

function Header() {
  return (
    <div className="header">
      <img src={kingLogo} alt="King Logo" className="logo" />
      <h1 className="heading">Ordenar</h1>
    </div>
  );
}

export default Header;
