var Base, BaseModel, Promise, TYPES,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

TYPES = require('./types');

Base = require('./base');

Promise = require('es6-promise').Promise;


/**
Base model class of DDD pattern.

the parent "Base" class just simply gives a @getFacade() method.


@class BaseModel
@extends Base
@module base-domain
 */

BaseModel = (function(superClass) {
  extend(BaseModel, superClass);

  function BaseModel() {
    return BaseModel.__super__.constructor.apply(this, arguments);
  }

  BaseModel.isEntity = false;


  /**
  key-value pair representing typeName - type
  
  use for definition of @properties for each extender
  
  @property TYPES
  @protected
  @final
  @static
  @type Object
   */

  BaseModel.TYPES = TYPES;


  /**
  key-value pair representing property's name - type of the model
  
      firstName    : @TYPES.STRING
      lastName     : @TYPES.STRING
      age          : @TYPES.NUMBER
      registeredAt : @TYPES.DATE
      team         : @TYPES.MODEL 'team'
      hobbies      : @TYPES.MODELS 'hobby'
      info         : @TYPES.ANY
  
  see types.coffee for full options.
  
  @property properties
  @abstract
  @static
  @type Object
   */

  BaseModel.properties = {};


  /*
  properties to cache, private.
   */

  BaseModel._propsInfo = void 0;

  BaseModel._propOfCreatedAt = void 0;

  BaseModel._propOfUpdatedAt = void 0;

  BaseModel._modelProps = void 0;


  /**
  get key-value pair representing property's name - type info of the model
  if prop name is given, returns the info
  
  @method getPropertyInfo
  @public
  @static
  @param {String} prop
  @return {Object}
   */

  BaseModel.getPropertyInfo = function(prop) {
    var _prop, ref, type, typeInfo;
    if (this._propsInfo == null) {
      this._propsInfo = {};
      ref = this.properties;
      for (_prop in ref) {
        type = ref[_prop];
        typeInfo = this.TYPES.info(type);
        this._propsInfo[_prop] = typeInfo;
      }
    }
    if (prop) {
      return this._propsInfo[prop];
    } else {
      return this._propsInfo;
    }
  };


  /**
  get prop name whose type is CREATED_AT
  notice: only one prop should be enrolled to CREATED_AT
  
  @method getPropOfCreatedAt
  @public
  @static
  @return {String} propName
   */

  BaseModel.getPropOfCreatedAt = function() {
    var prop, ref, type;
    if (this._propOfCreatedAt === void 0) {
      this._propOfCreatedAt = null;
      ref = this.properties;
      for (prop in ref) {
        type = ref[prop];
        if (type === this.TYPES.CREATED_AT) {
          this._propOfCreatedAt = prop;
          break;
        }
      }
    }
    return this._propOfCreatedAt;
  };


  /**
  get prop name whose type is UPDATED_AT
  notice: only one prop should be enrolled to UPDATED_AT
  
  @method getPropOfUpdatedAt
  @public
  @static
  @return {String} propName
   */

  BaseModel.getPropOfUpdatedAt = function() {
    var prop, ref, type;
    if (this._propOfUpdatedAt === void 0) {
      this._propOfUpdatedAt = null;
      ref = this.properties;
      for (prop in ref) {
        type = ref[prop];
        if (type === this.TYPES.UPDATED_AT) {
          this._propOfUpdatedAt = prop;
          break;
        }
      }
    }
    return this._propOfUpdatedAt;
  };


  /**
  get list of properties which contains relational model
  
  @method getModelProps
  @public
  @static
  @return {Array}
   */

  BaseModel.getModelProps = function() {
    var prop, ref, typeInfo;
    if (this._modelProps == null) {
      this._modelProps = [];
      ref = this.getPropertyInfo();
      for (prop in ref) {
        typeInfo = ref[prop];
        if (typeInfo.model != null) {
          this._modelProps.push(prop);
        }
      }
    }
    return this._modelProps;
  };


  /**
  set value to prop
  @return {BaseModel} this
   */

  BaseModel.prototype.set = function(prop, value) {
    var k, typeInfo, v;
    if (typeof prop === 'object') {
      for (k in prop) {
        v = prop[k];
        this.set(k, v);
      }
      return this;
    }
    typeInfo = this.constructor.getPropertyInfo(prop);
    if (typeInfo != null ? typeInfo.model : void 0) {
      this.setRelatedModel(prop, value);
    } else {
      this.setNonModelProp(prop, value);
    }
    return this;
  };


  /**
  set model prop
  @return {BaseModel} this
   */

  BaseModel.prototype.setNonModelProp = function(prop, value) {
    return this[prop] = value;
  };


  /**
  synchronize relation columns and relationId columns
  
  @param {Object} [options]
  @param {Boolean} [options.force]
  @method updateRelationIds
   */

  BaseModel.prototype.updateRelationIds = function(options) {
    var i, len, modelName, propName, propValue, ref, typeInfo;
    if (options == null) {
      options = {};
    }
    ref = this.constructor.getModelProps();
    for (i = 0, len = ref.length; i < len; i++) {
      propName = ref[i];
      typeInfo = this.constructor.getPropertyInfo(propName);
      modelName = typeInfo.model;
      propValue = this[propName];
      this.setRelatedModel(propName, propValue);
    }
    return this;
  };


  /**
  set related model(s)
  
  @method setRelatedModel
  @param {String} prop property name of the related model
  @param {Entity|Array<Entity>} submodel
  @return {BaseModel} this
   */

  BaseModel.prototype.setRelatedModel = function(prop, submodel) {
    var idPropName, modelName, sub, typeInfo;
    this.assertSubModelProp(prop, 'setRelatedModel(s)');
    typeInfo = this.constructor.getPropertyInfo(prop);
    modelName = typeInfo.model;
    this[prop] = submodel;
    if (!this.isSubClassOfEntity(modelName)) {
      return this;
    }
    idPropName = typeInfo.idPropName;
    if (typeInfo.name === 'MODEL') {
      this[idPropName] = submodel != null ? submodel.id : void 0;
    } else {
      this[idPropName] = submodel ? (function() {
        var i, len, results1;
        results1 = [];
        for (i = 0, len = submodel.length; i < len; i++) {
          sub = submodel[i];
          results1.push(sub.id);
        }
        return results1;
      })() : [];
    }
    return this;
  };


  /**
  alias for setRelatedModel
  
  @method setRelatedModels
   */

  BaseModel.prototype.setRelatedModels = function(prop, submodels) {
    return this.setRelatedModel(prop, submodels);
  };


  /**
  unset related model(s)
  
  @param {String} prop property name of the related models
  @return {BaseModel} this
  @method setRelatedModels
   */

  BaseModel.prototype.unsetRelatedModel = function(prop) {
    var idPropName, modelName, typeInfo;
    this.assertSubModelProp(prop, 'unsetRelatedModel(s)');
    typeInfo = this.constructor.getPropertyInfo(prop);
    modelName = typeInfo.model;
    idPropName = typeInfo.idPropName;
    this[prop] = void 0;
    if (typeInfo.name === 'MODEL') {
      this[idPropName] = void 0;
    } else {
      this[idPropName] = [];
    }
    return this;
  };


  /**
  alias for unsetRelatedModel
  
  @method unsetRelatedModels
   */

  BaseModel.prototype.unsetRelatedModels = function(prop, submodels) {
    return this.unsetRelatedModel(prop, submodels);
  };


  /**
  add related models
  
  @param {String} prop property name of the related models
  @return {BaseModel} this
  @method addRelatedModels
   */

  BaseModel.prototype.addRelatedModels = function() {
    var i, idPropName, j, len, len1, modelName, prop, submodel, submodels, typeInfo;
    prop = arguments[0], submodels = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    this.assertSubModelProp(prop, 'addRelatedModels');
    typeInfo = this.constructor.getPropertyInfo(prop);
    modelName = typeInfo.model;
    if (typeInfo.name !== 'MODELS') {
      throw this.getFacade().error(this.constructor.name + ".addRelatedModels(" + prop + ")\n" + prop + " is not a prop for models.");
    }
    idPropName = typeInfo.idPropName;
    if (this[prop] == null) {
      this[prop] = [];
    }
    for (i = 0, len = submodels.length; i < len; i++) {
      submodel = submodels[i];
      this[prop].push(submodel);
    }
    if (this[idPropName] == null) {
      this[idPropName] = [];
    }
    for (j = 0, len1 = submodels.length; j < len1; j++) {
      submodel = submodels[j];
      this[idPropName].push(submodel.id);
    }
    return this;
  };


  /**
  inherit value of anotherModel
  
  @method inherit
  @param {BaseModel} anotherModel
  @return {BaseModel} this
   */

  BaseModel.prototype.inherit = function(anotherModel) {
    var k, v;
    for (k in anotherModel) {
      if (!hasProp.call(anotherModel, k)) continue;
      v = anotherModel[k];
      if (v != null) {
        this[k] = v;
      }
    }
    return this;
  };


  /**
  create plain object without relational entities
  descendants of Entity are removed, but not descendants of BaseModel
  descendants of Entity in descendants of BaseModel are removed ( = recursive)
  
  @method toPlainObject
  @return {Object} plainObject
   */

  BaseModel.prototype.toPlainObject = function() {
    var facade, plainObject, prop, propInfoMap, subData, typeInfo, value;
    propInfoMap = this.constructor.getPropertyInfo();
    facade = this.getFacade();
    plainObject = {};
    for (prop in this) {
      if (!hasProp.call(this, prop)) continue;
      value = this[prop];
      typeInfo = propInfoMap[prop];
      if ((typeInfo != null ? typeInfo.model : void 0) == null) {
        plainObject[prop] = value;
        continue;
      }
      if (this.isSubClassOfEntity(typeInfo.model)) {
        continue;
      }
      if (typeInfo.name === 'MODEL') {
        if (value instanceof BaseModel) {
          plainObject[prop] = value.toPlainObject();
        } else {
          plainObject[prop] = value;
        }
      } else {
        plainObject[prop] = (function() {
          var i, len, results1;
          results1 = [];
          for (i = 0, len = value.length; i < len; i++) {
            subData = value[i];
            if (subData instanceof BaseModel) {
              results1.push(subData.toPlainObject());
            } else {
              results1.push(subData);
            }
          }
          return results1;
        })();
      }
    }
    return plainObject;
  };


  /**
  include all relational models if not set
  
  @method includeAll
  @param {Object} [options]
  @param {Boolean|Object} [options.recursive] recursively include models or not. unstable.
  @return {Promise(BaseModel)} self
   */

  BaseModel.prototype.include = function(options) {
    var facade, m, modelName, modelPool, promises, ref;
    if (options == null) {
      options = {};
    }
    facade = this.getFacade();
    modelPool = (ref = options.modelPool) != null ? ref : {};
    if (options.recursive) {
      modelName = this.constructor.getModelName();
      modelPool[modelName] = {};
      if (this.id != null) {
        modelPool[modelName][this.id] = this;
      }
    }
    promises = (function() {
      var i, len, ref1, results1;
      ref1 = this.constructor.getModelProps();
      results1 = [];
      for (i = 0, len = ref1.length; i < len; i++) {
        m = ref1[i];
        results1.push((function(_this) {
          return function(modelProp) {
            var novelRelIds, objs, promise, propInfo, relId, relIds, repo;
            propInfo = _this.constructor.getPropertyInfo(modelProp);
            if ((_this[modelProp] == null) && ((relId = _this[propInfo.idPropName]) != null) && _this.isSubClassOfEntity(propInfo.model)) {
              repo = facade.createRepository(propInfo.model);
              promise = (function() {
                var j, len1, ref2, ref3;
                if (Array.isArray(relId)) {
                  relIds = relId;
                  objs = [];
                  novelRelIds = [];
                  for (j = 0, len1 = relIds.length; j < len1; j++) {
                    relId = relIds[j];
                    if (((ref2 = modelPool[propInfo.model]) != null ? ref2[relId] : void 0) != null) {
                      objs.push(modelPool[propInfo.model][relId]);
                    } else {
                      novelRelIds.push(relId);
                    }
                  }
                  if (objs.length === relIds.length) {
                    return Promise.resolve(objs);
                  } else {
                    return repo.query({
                      where: {
                        id: {
                          inq: novelRelIds
                        }
                      }
                    }).then(function(results) {
                      return objs = objs.concat(results);
                    });
                  }
                } else {
                  if (((ref3 = modelPool[propInfo.model]) != null ? ref3[relId] : void 0) != null) {
                    Promise.resolve(modelPool[propInfo.model][relId]);
                  }
                  return repo.get(relId);
                }
              })();
              return promise.then(function(val) {
                return _this.set(modelProp, val);
              })["catch"](function(e) {});
            }
          };
        })(this)(m));
      }
      return results1;
    }).call(this);
    return Promise.all(promises).then((function(_this) {
      return function() {
        var i, j, len, len1, model, modelProp, promise, propInfo, ref1, ref2, subPromises;
        if (!options.recursive) {
          return _this;
        }
        subPromises = [];
        ref1 = _this.constructor.getModelProps();
        for (i = 0, len = ref1.length; i < len; i++) {
          modelProp = ref1[i];
          propInfo = _this.constructor.getPropertyInfo(modelProp);
          if (propInfo.name === 'MODELS' && Array.isArray(_this[modelProp])) {
            ref2 = _this[modelProp];
            for (j = 0, len1 = ref2.length; j < len1; j++) {
              model = ref2[j];
              if (model instanceof BaseModel) {
                promise = model.include({
                  recursive: true,
                  modelPool: modelPool
                });
                subPromises.push(promise);
              }
            }
          } else {
            model = _this[modelProp];
            if (model instanceof BaseModel) {
              promise = model.include({
                recursive: true,
                modelPool: modelPool
              });
              subPromises.push(promise);
            }
          }
        }
        return Promise.all(subPromises);
      };
    })(this)).then((function(_this) {
      return function() {
        return _this;
      };
    })(this));
  };


  /**
  assert given prop is model prop
  
  @method assertSubModelProp
  @private
   */

  BaseModel.prototype.assertSubModelProp = function(prop, method) {
    var typeInfo;
    typeInfo = this.constructor.getPropertyInfo(prop);
    if ((typeInfo == null) || !typeInfo.model) {
      throw this.getFacade().error(this.constructor.name + "." + method + "(" + prop + ")\n" + prop + " is not a prop for model.");
    }
  };

  BaseModel.getModelName = function() {
    return this.name.replace(/([A-Z])/g, function(st) {
      return '-' + st.charAt(0).toLowerCase();
    }).slice(1);
  };


  /**
  return if Model is subclass of Entity
  
  @method isSubClassOfEntity
  @private
   */

  BaseModel.prototype.isSubClassOfEntity = function(modelName) {
    var ModelClass;
    ModelClass = this.getFacade().getModel(modelName);
    return ModelClass.isEntity;
  };

  return BaseModel;

})(Base);

module.exports = BaseModel;