// src/Components/Card/Card.jsx
import React from "react";
import "./Card.css";
import Button from "../Button/Button";

function Card({ food, onAdd, onRemove, count }) {
  const { title, Image, price } = food;

  return (
    <div className="card">
      <span className={`${count !== 0 ? "card__badge" : "card__badge--hidden"}`}>
        {count}
      </span>

      <div className="image__container">
        <img src={Image} alt={title} />
      </div>

      <h4 className="card__title">
        {title} <span className="card__price">Bs {price}</span>
      </h4>

      <div className="btn-container">
        <Button
          title={count === 0 ? "añadir" : "+"}
          type="add"
          onClick={() => onAdd(food)}
        />
        {count !== 0 && (
          <Button title="-" type="remove" onClick={() => onRemove(food)} />
        )}
      </div>
    </div>
  );
}

export default Card;
