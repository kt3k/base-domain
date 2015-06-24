
BaseModel = require './base-model'
EventedArrayGenerator = require './evented-array-generator'

###*
list class of DDD pattern.

@class BaseList
@extends BaseModel
@module base-domain
###
class BaseList extends BaseModel

    ###*
    model name of the item

    @property itemModelName
    @static
    @protected
    @type String
    ###
    @itemModelName: ''


    ###*
    key of the item in this list
    returns null or undefined if no keys is needed
    if key is set, we can get model by key by @has()

        memberModel = id: 'shin', name: 'Shin Suzuki'
        memberList.setItems([memberModel])

        memberList.has('shin')  # true
        memberList.has('kohta') # false

    @method key
    @static
    @param {Model} item
    @return {String|Number}
    ###
    @key: (item) -> item.id


    ###*
    creates child class of BaseList

    @method getAnonymousClass
    @params {String} itemModelName
    @return {Function} child class of BaseList
    ###
    @getAnonymousClass: (itemModelName) ->


        class AnonymousList extends BaseList
            @itemModelName: itemModelName
            @isAnonymous: true

        return AnonymousList


    ###*
    ids: get ids of items

    @property ids
    @type Array
    @public
    ###
    Object.defineProperty @::, 'ids',
        get: ->
            return null if not @constructor.containsEntity()
            return (item.id for item in @items)

    ###*
    items: array of models

    @property items
    @type Array
    ###

    ###*
    loaded: is data loaded or not

    @property loaded
    @type Boolean
    ###

    ###*
    itemFactory: instance of factory which creates item models

    @property itemFactory
    @type BaseFactory
    ###

    ###*
    @constructor
    ###
    constructor: (props = {}) ->

        # loaded and listeners are hidden properties
        _itemFactory = null

        items = @createEmptyItemArray() # just an array. observes bang methods.

        Object.defineProperties @, 
            items       : value: items, enumerable: true
            dic         : value: {}
            loaded      : value: false, writable: true
            listeners   : value: []
            itemFactory : get: ->
                _itemFactory ?= @getFacade().createFactory(@constructor.itemModelName, true)

        if props.items
            @setItems props.items

        if props.ids
            @setIds props.ids

        super(props)


    createEmptyItemArray : ->
        items = EventedArrayGenerator.generate(@)
        items.on 'added',  @setKeys
        items.on 'removed',@unsetKeys
        return items


    ###*
    set keys of new items to dic

    @method setKeys
    @private
    @param {Array(BaseModel)} newItems
    ###
    setKeys: (newItems) ->
        for newItem in newItems
            key = @constructor.key(newItem)
            @dic[key] = newItem if key?

    ###*
    unset keys of deleted items in dic

    @method unsetKeys
    @private
    @param {Array(BaseModel)} deletedItems
    ###
    unsetKeys: (deletedItems) ->
        for deletedItem in deletedItems
            key = @constructor.key(deletedItem)
            delete @dic[key] if key?

    ###*
    check if items has model by key

    @public
    @method has
    @param {String|Number} key
    @return {Boolean}
    ###
    has: (key) -> @dic[key]?


    ###*
    get an item by key

    @public
    @method getByKey
    @param {String|Number} key
    @return {BaseModel} item
    ###
    getByKey: (key) -> @dic[key]


    ###*
    set ids.

    @method setIds
    @param {Array(String|Number)} ids 
    ###
    setIds: (ids = []) ->

        return if not @constructor.containsEntity()

        @loaded = false
        ItemRepository = @getFacade().getRepository(@constructor.itemModelName)

        repo = new ItemRepository()

        if ItemRepository.storeMasterTable and ItemRepository.loaded()

            subModels = (repo.getByIdSync(id) for id in ids)
            @setItems(subModels)

        else
            repo.query(where: id: inq: ids).then (subModels) =>
                @setItems(subModels)

        return @


    ###*
    set items

    @method setItems
    @param {Array} models
    ###
    setItems: (models = []) ->
        ItemClass = @getFacade().getModel @constructor.itemModelName

        @items.push item for item in models when item instanceof ItemClass

        @items.sort(@sort)

        @loaded = true
        @emitLoaded()
        return @

    ###*
    returns item is Entity

    @method containsEntity
    @static
    @public
    @return {Boolean}
    ###
    @containsEntity: ->
        return @getFacade().getModel(@itemModelName).isEntity


    ###*
    sort items in constructor

    @method sort
    @protected
    ###
    sort: (modelA, modelB) ->
        if modelA.id > modelB.id then 1 else -1


    ###*
    first item

    @method first
    @public
    ###
    first: ->
        if @items.length is 0
            return null

        return @items[0]


    ###*
    last item

    @method last
    @public
    ###
    last: ->
        if @items.length is 0
            return null

        return @items[@items.length - 1]


    ###*
    export models to Array

    @method toArray
    @public
    ###
    toArray: ->
        @items.slice()


    ###*
    create plain list.
    if this list contains entities, returns their ids
    if this list contains non-entity models, returns their plain objects 

    @method toPlainObject
    @return {Object} plainObject
    ###
    toPlainObject: ->

        plain = super()

        if @constructor.containsEntity()
            plain.ids = @ids
            delete plain.items

        else
            plainItems = []
            for item in @items
                if typeof item.toPlainObject is 'function'
                    plainItems.push item.toPlainObject()
                else
                    plainItems.push item

            plain.items = plainItems

        return plain


    ###*
    on addEventListeners for 'loaded'

    @method on
    @public
    ###
    on: (evtname, fn) ->
        return if evtname isnt 'loaded'

        if @loaded
            process.nextTick fn
        else if typeof fn is 'function'
            @listeners.push fn
        return


    ###*
    tell listeners emit loaded
    @method emitLoaded
    @private
    ###
    emitLoaded: ->
        while fn = @listeners.shift()
            process.nextTick fn
        return

module.exports = BaseList
