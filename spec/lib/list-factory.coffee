
facade = require('../create-facade').create()
Facade = facade.constructor
ListFactory = Facade.ListFactory

describe 'ListFactory', ->

    before ->
        class Hobby extends Facade.Entity
            @properties:
                name: @TYPES.STRING

        class NonEntity extends Facade.BaseModel
            @properties:
                name: @TYPES.STRING

        class HobbyRepository extends Facade.MasterRepository
            @modelName: 'hobby'

        class HobbyList extends Facade.BaseList
            @itemModelName: 'hobby'


        facade.addClass('hobby', Hobby)
        facade.addClass('non-entity', NonEntity)
        facade.addClass('hobby-list', HobbyList)
        facade.addClass('hobby-repository', HobbyRepository)

        @hobbyFactory = facade.createFactory('hobby', on)


    describe 'createEmpty', ->

        before ->
            hobbyListFactory = ListFactory.create('hobby-list', @hobbyFactory)
            @hobbyList = hobbyListFactory.createEmpty()

        it 'creates list', ->

            expect(@hobbyList).to.be.instanceof Facade.BaseList
            expect(@hobbyList.items).to.be.instanceof Array
            expect(@hobbyList.loaded).to.be.true

        it 'creates empty list', ->
            expect(@hobbyList.items).to.have.length 0
            expect(@hobbyList.ids).to.have.length 0


    describe 'createFromObject', ->

        it 'regards arg as object when arg has items', ->

            obj = items: [ {name: 'keyboard'}, {name: 'programming'} ]

            hobbyListFactory = ListFactory.create('hobby-list', @hobbyFactory)
            list = hobbyListFactory.createFromObject(obj)
            expect(list.items).to.have.length 2


        it 'regards arg as list object when arg has ids', (done) ->

            obj = ids: ['dummy']

            hobbyListFactory = ListFactory.create('hobby-list', @hobbyFactory)
            list = hobbyListFactory.createFromObject(obj)

            list.on 'loaded', ->
                expect(list.items).to.have.length.above 0
                done()


    describe 'createFromArray', ->

        it 'regards string array as id list', (done) ->
            hobbyListFactory = ListFactory.create('hobby-list', @hobbyFactory)
            list = hobbyListFactory.createFromArray(['dummy'])

            list.on 'loaded', ->
                expect(list.items).to.have.length.above 0
                done()

        it 'regards object array as pre-model list', (done) ->

            data = [ {id: 3, name: 'keyboard'}, {id: 2, name: 'sailing'} ]

            hobbyListFactory = ListFactory.create('hobby-list', @hobbyFactory)
            list = hobbyListFactory.createFromArray(data)

            list.on 'loaded', ->
                Hobby = facade.getModel 'hobby'
                expect(list.items).to.have.length 2
                expect(list.items[0]).to.be.instanceof Hobby
                expect(list.ids).to.eql [2,3]
                done()

