'use strict'

Util = require '../util'

GeneralFactory = require './general-factory'
MasterDataResource = require '../master-data-resource'
ModelProps = require './model-props'
BaseModule = require './base-module'
CoreModule = require './core-module'

###*
Facade class of DDD pattern.

- create instance of factories
- create instance of repositories

@class Facade
@implements RootInterface
@module base-domain
###
class Facade

    ###*
    is root (to identify RootInterface)
    @property {Boolean} isRoot
    @static
    ###
    @isRoot: true


    ###*
    Get facade

    @method getFacade
    @return {Facade}
    @chainable
    ###
    getFacade: -> @


    ###*
    Latest instance created via @createInstance()
    This instance will be attached base instances with no @root property.

    @property {Facade} latestInstance
    @static
    ###
    @latestInstance: null


    ###*
    create instance of Facade

    @method createInstance
    @static
    @param {Object} [options]
    @return {Facade}
    ###
    @createInstance: (options = {}) ->
        Constructor = @
        instance = new Constructor(options)
        Facade.latestInstance = instance
        return instance


    ###*
    constructor

    @constructor
    @param {String} [options]
    @param {String} [options.dirname="."] path where domain definition files are included
    @param {Object} [options.preferred={}]
    @param {Object} [options.preferred.repository] key: firstName, value: repository name used in facade.createPreferredRepository(firstName)
    @param {Object} [options.preferred.factory] key: firstName, value: factory name used in facade.createPreferredFactory(firstName)
    @param {Object} [options.preferred.service] key: firstName, value: service name used in facade.createPreferredService(firstName)
    @param {String|Array(String)} [options.preferred.module] module prefix attached to load preferred class
    @param {Boolean} [options.master] if true, MasterDataResource is enabled.
    ###
    constructor: (options = {}) ->

        Object.defineProperties @,
            nonExistingClassNames: value: {}
            classes   : value: {}
            modelProps: value: {}
            modules   : value: {}
            preferred : value:
                repository : Util.clone(options.preferred?.repository) ? {}
                factory    : Util.clone(options.preferred?.factory) ? {}
                service    : Util.clone(options.preferred?.service) ? {}
                module     : options.preferred?.module

        @dirname = options.dirname ? '.'

        for moduleName, path of Util.clone(options.modules ? {})
            @modules[moduleName] = new BaseModule(moduleName, path, @)
        @modules.core = new CoreModule(@dirname, @)

        if options.master
            ###*
            instance of MasterDataResource
            Exist only when "master" property is given to Facade's option

            @property {MasterDataResource} master
            @optional
            @readOnly
            ###
            @master = new MasterDataResource(@)

        @init()
        @master?.init()


    # for base-domainify. keep it empty
    init: ->


    ###*
    get a model class

    @method getModel
    @param {String} modFullName
    @return {Function}
    ###
    getModel: (modFullName) ->
        return @require(modFullName)


    ###*
    create an instance of the given modFirstName using obj
    if obj is null or undefined, empty object will be created.

    @method createModel
    @param {String} modFirstName
    @param {Object} obj
    @param {Object} [options]
    @param {RootInterface} [root]
    @return {BaseModel}
    ###
    createModel: (modFirstName, obj, options, root) ->
        GeneralFactory.createModel(modFirstName, obj, options, root ? @)


    ###*
    create a factory instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the factory

    @method createFactory
    @param {String} modFirstName
    @return {BaseFactory}
    ###
    createFactory: (modFirstName, params...) ->
        @__create(modFirstName, 'factory', params, @)


    ###*
    create a repository instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the repository

    @method createRepository
    @param {String} modFirstName
    @return {BaseRepository}
    ###
    createRepository: (modFirstName, params...) ->
        @__create(modFirstName, 'repository', params, @)


    ###*
    create a service instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the service

    @method createService
    @param {String} modFirstName
    @return {BaseService}
    ###
    createService: (modFirstName, params...) ->
        @__create(modFirstName, 'service', params, @)


    __create: (modFirstName, type, params, root) ->

        modFullName = if type then modFirstName + '-' + type else modFirstName

        Class = ClassWithConstructor = @require(modFullName)

        while ClassWithConstructor.length is 0 and ClassWithConstructor isnt Object
            ClassWithConstructor = Util.getProto(ClassWithConstructor::).constructor

        while params.length < ClassWithConstructor.length - 1
            params.push undefined

        return new Class(params..., root ? @)


    ###*
    create a preferred repository instance
    3rd, 4th ... arguments are the params to pass to the constructor of the repository

    @method createPreferredRepository
    @param {String} firstName
    @param {Object} [options]
    @param {Object} [options.noParent] if true, stop requiring parent class
    @return {BaseRepository}
    ###
    createPreferredRepository: (firstName, options, params...) ->

        @createPreferred(firstName, 'repository', options, params, @)


    ###*
    create a preferred factory instance
    3rd, 4th ... arguments are the params to pass to the constructor of the factory

    @method createPreferredFactory
    @param {String} firstName
    @param {Object} [options]
    @param {Object} [options.noParent=true] if true, stop requiring parent class
    @return {BaseFactory}
    ###
    createPreferredFactory: (firstName, options = {}, params...) ->

        options.noParent ?= true

        @createPreferred(firstName, 'factory', options, params, @)


    ###*
    create a preferred service instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the factory

    @method createPreferredService
    @param {String} firstName
    @param {Object} [options]
    @param {Object} [options.noParent=true] if true, stop requiring parent class
    @return {BaseService}
    ###
    createPreferredService: (firstName, options = {}, params...) ->

        options.noParent ?= true

        @createPreferred(firstName, 'service', options, params, @)


    ###*
    create a preferred factory|repository|service instance

    @method createPreferred
    @private
    @param {String} firstName
    @param {String} type factory|repository|service
    @param {Object} [options]
    @param {Object} [params] params pass to constructor of Repository, Factory or Service
    @param {RootInterface} root
    @return {BaseFactory}
    ###
    createPreferred: (firstName, type, options = {}, params, root) ->

        originalFirstName = firstName

        loop
            modFullName = @getPreferredName(firstName, type)

            if @hasClass(modFullName)
                return @__create(modFullName, null, params, root)

            if options.noParent
                throw @error("preferred#{type}NotFound", "preferred #{type} of '#{originalFirstName}' is not found")

            ParentClass = @require(firstName).getParent()

            if not ParentClass.className
                throw @error("preferred#{type}NotFound", "preferred #{type} of '#{originalFirstName}' is not found")

            firstName = ParentClass.getName()


    ###*
    @method getPreferredName
    @private
    @param {String} firstName
    @param {String} type repository|factory|service
    @return {String} modFullName
    ###
    getPreferredName: (firstName, type) ->

        modFullName = @preferred[type][firstName]
        return modFullName if modFullName and @hasClass(modFullName)

        if @preferred.module and @modules[@preferred.module]?
            moduleName = @preferred.module
        else
            moduleName = 'core'

        return @getModule(moduleName).normalizeName(firstName + '-' + type)


    ###*
    read a file and returns class

    @method require
    @private
    @param {String} modFullName
    @return {Function}
    ###
    require: (modFullName_o) ->

        modFullName = @getModule('core').normalizeName(modFullName_o)

        return @classes[modFullName] if @classes[modFullName]?

        moduleName = @moduleName(modFullName)
        fullName   = @fullName(modFullName)

        if not @nonExistingClassNames[modFullName] # avoid searching non-existing files many times
            klass = @getModule(moduleName).requireOwn(fullName)

        if not klass?
            @nonExistingClassNames[modFullName] = true

            modFullName = fullName # strip module name
            klass = @getModule('core').requireOwn(fullName)

        if not klass?
            @nonExistingClassNames[fullName] = true
            throw @error('modelNotFound', "model '#{modFullName_o}' is not found")

        @nonExistingClassNames[modFullName] = false
        @addClass modFullName, klass


    ###*
    @method getModule
    @param {String} moduleName
    @return {BaseModule}
    ###
    getModule: (moduleName) ->
        @modules[moduleName]


    ###*
    get moduleName from modFullName
    @method moduleName
    @private
    @param {String} modFullName
    @return {String}
    ###
    moduleName: (modFullName) ->
        if modFullName.match '/' then modFullName.split('/')[0] else 'core'


    ###*
    get fullName from modFullName
    @method fullName
    @private
    @param {String} modFullName
    @return {String}
    ###
    fullName: (modFullName) ->
        if modFullName.match '/' then modFullName.split('/')[1] else modFullName



    ###*
    check existence of the class of the given name

    @method hasClass
    @param {String} modFullName
    @return {Function}
    ###
    hasClass: (modFullName) ->

        modFullName = @getModule('core').normalizeName(modFullName)

        return false if @nonExistingClassNames[modFullName]

        try
            @require(modFullName)
            return true
        catch e
            return false


    ###*
    add class to facade.
    the class is acquired by @require(modFullName)

    @method addClass
    @private
    @param {String} modFullName
    @param {Function} klass
    @return {Function}
    ###
    addClass: (modFullName, klass) ->

        modFullName = @getModule('core').normalizeName(modFullName)

        klass.className = modFullName
        klass.moduleName = @moduleName(modFullName)

        delete @nonExistingClassNames[modFullName]

        @classes[modFullName] = klass


    ###*
    Get ModelProps by firstName.
    ModelProps summarizes properties of this class

    @method getModelProps
    @param {String} firstName
    @return {ModelProps}
    ###
    getModelProps: (firstName) ->

        #modFullName = @getPreferredName(firstName) # TODO
        modFullName = firstName # TODO attach default module name

        if not @modelProps[modFullName]?

            Model = @getModel(modFullName)

            @modelProps[modFullName] = new ModelProps(modFullName, Model.properties, @)

        return @modelProps[modFullName]

    ###*
    create instance of DomainError

    @method error
    @param {String} reason reason of the error
    @param {String} [message]
    @return {Error}
    ###
    error: (reason, message) ->

        DomainError = @constructor.DomainError
        return new DomainError(reason, message)


    ###*
    check if given object is instance of DomainError

    @method isDomainError
    @param {Error} e
    @return {Boolean}
    ###
    isDomainError: (e) ->

        DomainError = @constructor.DomainError
        return e instanceof DomainError


    ###*
    insert fixture data
    (Node.js only)

    @method insertFixtures
    @param {Object} [options]
    @param {String} [options.dataDir='./data'] directory to have fixture data files
    @param {String} [options.tsvDir='./tsv'] directory to have TSV files
    @param {Array(String)} [options.models=null] model firstNames to insert. default: all models
    @return {Promise(EntityPool)} inserted data
    ###
    insertFixtures: (options = {}) ->

        Fixture = require '../fixture'
        fixture = new Fixture(@, options)
        fixture.insert(options.models)


    @Base                : require './base'
    @BaseModel           : require './base-model'
    @BaseService         : require './base-service'
    @ValueObject         : require './value-object'
    @Entity              : require './entity'
    @AggregateRoot       : require './aggregate-root'
    @Collection          : require './collection'
    @BaseList            : require './base-list'
    @BaseDict            : require './base-dict'
    @BaseFactory         : require './base-factory'
    @BaseRepository      : require './base-repository'
    @BaseSyncRepository  : require './base-sync-repository'
    @BaseAsyncRepository : require './base-async-repository'
    @LocalRepository     : require './local-repository'
    @MasterRepository    : require './master-repository'
    @DomainError         : require './domain-error'
    @GeneralFactory      : require './general-factory'


module.exports = Facade
