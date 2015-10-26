
Entity = require('../base-domain').Entity


class Member extends Entity

    @properties:
        firstName    : @TYPES.STRING
        age          : @TYPES.NUMBER
        registeredAt : @TYPES.DATE
        hobbies      : @TYPES.MODEL 'hobby-list'
        newHobbies   : @TYPES.MODEL 'hobby-list'
        mCreatedAt   : @TYPES.CREATED_AT
        mUpdatedAt   : @TYPES.UPDATED_AT


module.exports = Member
