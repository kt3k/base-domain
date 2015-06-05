
BaseList = require './base-list'
Base = require './base'


###*
factory of list

@class ListFactory
@extends Base
@module base-domain
###
class ListFactory extends Base

    constructor: (@listModelName, @itemModelName) ->

        @ListClass = @getFacade().getListModel(@listModelName, @itemModelName)


    ###*
    creates an instance of BaseList by value

    @method createList
    @public
    @param {any} value
    @return {BaseList}
    ###
    createList: (value) ->

        if not value? or typeof value isnt 'object'
            return @createEmpty()

        if not Array.isArray value
            return @createFromObject(value)

        return @createFromArray(value)



    ###*
    creates an instance of BaseList from array

    @method createFromArray
    @private
    @param {Array} arr
    @return {BaseList}
    ###
    createFromArray: (arr) ->

        firstValue = arr[0]

        if not firstValue?
            return @createEmpty()

        if typeof firstValue is 'object'
            return @createFromObjectList(arr)

        if @ListClass.containsEntity()
            return @createFromIds(arr)

        throw new Error "cannot create #{@listModelName} with arr\n [#{arr.toString()}]"

    ###*
    creates an instance of BaseList by value

    @method createEmpty
    @private
    @return {BaseList}
    ###
    createEmpty: ->

        return new @ListClass()


    ###*
    creates an instance of BaseList by value

    @method createFromObject
    @private
    @params {Object} obj
    @return {BaseList}
    ###
    createFromObject: (obj) ->

        if obj.items and Array.isArray obj.items

            return @createFromArray(obj)

        if obj.ids and Array.isArray obj.items

            return @createFromArray(obj)

        # regard the obj as (pre)model
        objList = [obj]
        return @createFromObjectList objList


    ###*
    creates an instance of BaseList by value

    @method createFromObjectList
    @private
    @params {Array(Object)} objList
    @return {BaseList}
    ###
    createFromObjectList: (objList) ->

        itemFactory = @getFacade().createFactory(@itemModelName, true)

        SubModel = itemFactory.getModelClass()

        subModels = (itemFactory.createFromObject(subObj) for subObj in objList)

        return new @ListClass(subModels)


    ###*
    creates an instance of BaseList by value

    @method createFromIds
    @private
    @params {Array(String|Number)} ids
    @return {BaseList}
    ###
    createFromIds: (ids) ->

        ItemRepository = @getFacade().getRepository(@itemModelName)

        repo = new ItemRepository()

        if ItemRepository.storeMasterTable and ItemRepository.loaded()

            items = (repo.getByIdSync(id) for id in ids)

            return new @ListClass(items)

        else

            modelsPromise = repo.query(where: id: inq: ids)

            return new @ListClass(modelsPromise)

module.exports = ListFactory
