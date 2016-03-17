
{ Util } = require './others'
{ Entity, ValueObject } = Facade = require('./base-domain')
facade = require('./create-facade').create()

describe 'Util', ->

    describe 'camelize', ->

        it 'converts larry-carlton to LarryCarlton', ->

            cameled = Util.camelize('larry-carlton')

            assert cameled is 'LarryCarlton'


        it 'converts get-element-by-id to getElementById when lowerFirst is true', ->

            cameled = Util.camelize('get-element-by-id', true)

            assert cameled is 'getElementById'


    describe 'hyphenize', ->

        it 'converts CureApp to cure-app', ->

            hyphenized = Util.hyphenize('CureApp')

            assert hyphenized is 'cure-app'


        it 'converts getElementById to get-element-by-id', ->

            hyphenized = Util.hyphenize('getElementById')

            assert hyphenized is 'get-element-by-id'


        it 'converts Room335 to room335', ->

            hyphenized = Util.hyphenize('Room335')

            assert hyphenized is 'room335'


        it 'converts WBC to w-b-c', ->

            hyphenized = Util.hyphenize('WBC')

            assert hyphenized is 'w-b-c'


    describe 'isInstance', ->

        it 'just the same result as "instanceof" operator when not in Titanium environment', ->

            F = ->
            f = new F
            assert Util.isInstance(f, F)
            assert Util.isInstance({}, F) is false


        it 'also returns the same result as "instanceof" operator, when class is given', ->

            class Human
            class Patient extends Human

            h = new Human
            p = new Patient
            o = {}
            n = null
            u = undefined

            assert Util.isInstance(p, Human)
            assert Util.isInstance(h, Human)
            assert Util.isInstance(h, Human)
            assert Util.isInstance(o, Human) is false
            assert Util.isInstance(n, Human) is false
            assert Util.isInstance(u, Human) is false

            assert Util.isInstance(p, Patient)
            assert Util.isInstance(h, Patient) is false
            assert Util.isInstance(o, Patient) is false
            assert Util.isInstance(n, Patient) is false
            assert Util.isInstance(u, Patient) is false

            assert Util.isInstance(p, Object)
            assert Util.isInstance(h, Object)
            assert Util.isInstance(o, Object)
            assert Util.isInstance(n, Object) is false
            assert Util.isInstance(u, Object) is false


        describe 'in Titanium environment', ->

            before ->
                # creates Ti in global scope
                getGlobal = -> @
                getGlobal().Ti = {}
                assert Ti?

            after ->
                getGlobal = -> @
                getGlobal().Ti = undefined
                assert not Ti?


            it 'also returns the same result as "instanceof" operator', ->
                F = ->
                f = new F
                assert Util.isInstance(f, F)
                assert Util.isInstance({}, F) is false

            it 'also returns the same result as "instanceof" operator, when class is given', ->

                class Human
                class Patient extends Human

                h = new Human
                p = new Patient
                o = {}
                n = null
                u = undefined

                assert Util.isInstance(p, Human)
                assert Util.isInstance(h, Human)
                assert Util.isInstance(h, Human)
                assert Util.isInstance(o, Human) is false
                assert Util.isInstance(n, Human) is false
                assert Util.isInstance(u, Human) is false

                assert Util.isInstance(p, Patient)
                assert Util.isInstance(h, Patient) is false
                assert Util.isInstance(o, Patient) is false
                assert Util.isInstance(n, Patient) is false
                assert Util.isInstance(u, Patient) is false

                assert Util.isInstance(p, Object)
                assert Util.isInstance(h, Object)
                assert Util.isInstance(o, Object)
                assert Util.isInstance(n, Object) is false
                assert Util.isInstance(u, Object) is false


    describe 'requireFile', ->

        it 'just requires a file', ->

            abc = Util.requireFile(__dirname + '/sample-files/abc')
            assert abc is 'abc'


        describe 'in Titanium environment', ->

            beforeEach ->
                getGlobal = -> @
                getGlobal().Ti =
                    Platform:
                        name: 'android'
                    Filesystem:
                        getFile: (a, b) ->
                        resourcesDirectory: 'Resources'

            afterEach ->
                getGlobal = -> @
                getGlobal().Ti = undefined
                assert not Ti?


            it 'just adds suffix ".js" and requires the path when platform is android', ->

                Ti.Filesystem.getFile = -> throw new Error 'this must not be called'

                abc = Util.requireFile(__dirname + '/sample-files/abc')
                assert abc is 'abc'


            it 'adds suffix ".js", checkes existence and requires when platform is not android', ->

                Ti.Platform.name = 'iPhone'

                Ti.Filesystem.getFile = (a, b) ->
                    exists: -> true

                abc = Util.requireFile(__dirname + '/sample-files/abc')
                assert abc is 'abc'


            it 'adds suffix ".js", checkes existence and throws an error when platform is not android and file does not exist', ->

                Ti.Platform.name = 'iPhone'

                Ti.Filesystem.getFile = (a, b) ->

                    exists: -> false

                expect(-> Util.requireFile(__dirname + '/sample-files/abc')).to.throw Error



    describe 'serialize', ->

        it 'converts null to "null"', ->
            assert Util.serialize(null) is 'null'

        it 'converts undefined to undefined', ->
            assert Util.serialize(undefined) is undefined

        it 'converts string to "string"', ->
            assert Util.serialize('string 123') is '"string 123"'

        it 'converts 123 to "123"', ->
            assert Util.serialize(123) is '123'

        it 'converts {a: 123, b: "str"} to equivalent to strinfified json', ->
            assert Util.serialize(a: 123, b: 'str') is JSON.stringify(a: 123, b: 'str')

        it 'converts plain array to equivalent to strinfified json', ->
            assert Util.serialize([a: 123, b: 'str']) is JSON.stringify([a: 123, b: 'str'])

        it 'converts error object to plain object with message and stack', ->
            e = new Error('err msg')
            e.prop1 = 'prop1 val'
            assert Util.serialize(e) is JSON.stringify({prop1: 'prop1 val', stack: e.stack, __errorMessage__: e.message})

        it 'attaches __className__ property to model ', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary = facade.createModel('diary', { p1: 123, p2: 'str' })
            assert Util.serialize(diary) is JSON.stringify { p1: 123, p2: 'str', __className__: 'diary' }
            assert diary.__className__ is undefined

        it 'attaches __className__ property to model when it is in array', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary = facade.createModel('diary', { p1: 123, p2: 'str' })
            assert Util.serialize([diary]) is JSON.stringify [{ p1: 123, p2: 'str', __className__: 'diary' }]

        it 'attaches __className__ property to model when it is in plain object', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary1 = facade.createModel('diary', { p1: 123, p2: 'str' })
            diary2 = facade.createModel('diary', { p1: 123, p2: 'str' })
            assert Util.serialize(d1: diary1, d2: diary2) is JSON.stringify d1: { p1: 123, p2: 'str', __className__: 'diary' }, d2: { p1: 123, p2: 'str', __className__: 'diary' }

        it 'does not attach __className__ property to model when it is in another model', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary1 = facade.createModel('diary', { p1: 123, p2: 'str' })
            diary2 = facade.createModel('diary', { p1: 123, p2: 'str' })
            diary1.d = diary2

            assert Util.serialize(diary1) is JSON.stringify { p1: 123, p2: 'str', d: { p1: 123, p2: 'str' }, __className__: 'diary' }


    describe 'deserialize', ->

        it 'restores null', ->
            serialized = Util.serialize(null)
            assert Util.deserialize(serialized, facade) is null

        it 'restores undefined', ->
            serialized = Util.serialize(undefined)
            assert Util.deserialize(serialized, facade) is undefined

        it 'restores 123', ->
            serialized = Util.serialize(123)
            assert Util.deserialize(serialized, facade) is 123

        it 'restores object', ->
            serialized = Util.serialize(a: 123, b: 'str')
            expect(Util.deserialize(serialized, facade)).to.eql {a: 123, b: 'str'}

        it 'restores array', ->
            serialized = Util.serialize([a: 123, b: 'str'])
            expect(Util.deserialize(serialized, facade)).to.eql [{a: 123, b: 'str'}]

        it 'restores error', ->
            e = new Error('err msg')
            e.prop1 = 'prop1 val'
            serialized = Util.serialize(e)
            expect(Util.deserialize(serialized, facade)).to.eql e

        it 'restores model', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary = facade.createModel('diary', { p1: 123, p2: 'str' })
            serialized = Util.serialize(diary)
            expect(Util.deserialize(serialized, facade)).to.eql diary
            assert Util.deserialize(serialized, facade) instanceof Diary
            assert Util.deserialize(serialized, facade).__className__ is undefined

        it 'restores model in array', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary = facade.createModel('diary', { p1: 123, p2: 'str' })
            serialized = Util.serialize([diary])
            expect(Util.deserialize(serialized, facade)).to.eql [diary]

        it 'restores model in object', ->
            class Diary extends Entity
            facade.addClass('diary', Diary)
            diary1 = facade.createModel('diary', { p1: 123, p2: 'str' })
            diary2 = facade.createModel('diary', { p1: 123, p2: 'str' })
            serialized = Util.serialize(d1: diary1, d2: diary2)
            expect(Util.deserialize(serialized, facade)).to.eql d1: diary1, d2: diary2
