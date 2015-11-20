'use strict'

Collection = require './collection'

###*
dictionary-structured data model

@class BaseDict
@extends Collection
@module base-domain
###
class BaseDict extends Collection

    ###*
    get unique key from item

    @method key
    @static
    @protected
    ###
    @key: (item) -> item.id


    ###*
    the number of items

    @property {Number} itemLength
    @public
    ###
    Object.defineProperty @::, 'itemLength',
        get: ->
            return 0 if not @loaded()
            Object.keys(@items).length


    ###*
    items: dictionary of keys - models

    @property {Object} items
    ###

    ###*
    @constructor
    @params {any} props
    @params {RootInterface} root
    ###
    constructor: (props = {}, root) ->

        super(props, root)


    ###*
    @method initItems
    @protected
    ###
    initItems: ->
        @items = {}


    ###*
    check if the model has submodel of the given key or not

    @method has
    @public
    @param {String|Number} key
    @return {Boolean}
    ###
    has: (key) ->
        return false if not @loaded()
        @items[key]?

    ###*
    check if the model contains the given submodel or not

    @method contains
    @public
    @param {BaseModel} item
    @return {Boolean}
    ###
    contains: (item) ->
        return false if not @loaded()
        key = @constructor.key item
        sameKeyItem = @get(key)
        sameKeyItem?.equals item


    ###*
    turn on/off the value

    @method toggle
    @param {BaseModel} item
    ###
    toggle: (item) ->
        return if not @loaded()
        key = @constructor.key item
        if @has key
            @remove item
        else
            @add item


    ###*
    return submodel of the given key

    @method get
    @public
    @param {String|Number} key
    @return {BaseModel}
    ###
    get: (key) ->
        return undefined if not @loaded()
        @items[key]

    ###*
    add item to @items

    @method addItem
    @protected
    @param {BaseModel} item
    ###
    addItem: (item) ->

        key = @constructor.key item
        @items[key] = item


    ###*
    remove submodel from items
    both acceptable, keys and submodels

    @method remove
    @public
    @param {BaseModel|String|Number} item
    ###
    remove: (args...) ->

        return if not @loaded()

        ItemClass = @getItemModelClass()

        for arg in args
            if arg instanceof ItemClass
                key = @constructor.key(arg)
            else
                key = arg

            delete @items[key]

        return


    ###*
    export models to Array

    @method toArray
    @public
    ###
    toArray: ->
        return [] if not @loaded()
        (item for key, item of @items)


module.exports = BaseDict
