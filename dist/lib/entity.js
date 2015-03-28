var BaseModel, Entity,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

BaseModel = require('./base-model');


/**
Base model class with "id" column

@class Entity
@extends BaseModel
@module base-domain
 */

Entity = (function(superClass) {
  extend(Entity, superClass);

  function Entity() {
    return Entity.__super__.constructor.apply(this, arguments);
  }

  Entity.isEntity = true;


  /**
  primary key for the model
  
  @property id
  @type any
   */

  Entity.prototype.id = null;

  return Entity;

})(BaseModel);

module.exports = Entity;