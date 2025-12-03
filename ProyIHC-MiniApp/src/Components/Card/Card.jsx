import React from "react";
import "./Card.css";
import Button from "../Button/Button";

function Card({ food, onAdd, onRemove, count }) {
  const { title, Image, price } = food;

  return (
    <div className="card">
      <div className="card__image-container">
        <img src={Image} alt={title} className="card__image" />
        {count > 0 && (
          <div className="card__badge">{count}</div>
        )}
      </div>

      <div className="card__content">
        <h3 className="card__title">{title}</h3>
        
        <span className="card__price">Bs {price}</span>
        
        <div className="card__actions">
          {count === 0 ? (
            <Button
              title="añadir"
              type="add"
              onClick={() => onAdd(food)}
            />
          ) : (
            <>
              <Button
                title="−"
                type="remove"
                onClick={() => onRemove(food)}
              />
              <span className="card__count">{count}</span>
              <Button
                title="+"
                type="add"
                onClick={() => onAdd(food)}
              />
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default Card;