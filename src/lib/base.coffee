

###*
parent class of model, factory and repository.

gives them @getFacade() method.

@class Base
@module base-domain
###
class Base

    getFacade : ->
        throw new Error """
            Facade is not created yet, or you required domain classes not from Facade.
            Require domain classes by facade.getModel(), facade.getFactory(), facade.getRepository()
            to attach them getFacade() method.
        """

module.exports = Base
