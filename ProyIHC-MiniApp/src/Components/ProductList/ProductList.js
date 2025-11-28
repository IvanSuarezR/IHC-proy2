import React from "react";
import Card from "../Card/Card";

function ProductList({ foods, onAdd, onRemove }) {
  return (
    <div className="cards__container">
      {foods.map((food) => (
        <Card key={food.id} food={food} onAdd={onAdd} onRemove={onRemove} />
      ))}
    </div>
  );
}

export default ProductList;
