Promise = require('promise')
_ = require('../lib/util.coffee')

ValidationError = require('../lib/errors/validation_error.coffee')

describe "Util", ->
  lazy "validator", -> test: ->

  describe "#defaults", ->
    it "extends an object from the left to right", ->
      incomeOptions =
        a: 1
        b: 2

      options = _.defaults incomeOptions,
        b: 3
        c: 4

      expect(options).eql {a: 1, b: 2, c: 4}

  describe "#isString", ->
    it "correctly detects strings", ->
      expect(_.isString(null)).false
      expect(_.isString(false)).false
      expect(_.isString({})).false
      expect(_.isString([])).false
      expect(_.isString(undefined)).false
      expect(_.isString('')).true
      expect(_.isString(' ')).true

  describe "#isFunction", ->
    it "checks if a value is a function", ->
      expect(_.isFunction(null)).false
      expect(_.isFunction(true)).false
      expect(_.isFunction(false)).false
      expect(_.isFunction([])).false
      expect(_.isFunction([1])).false
      expect(_.isFunction({})).false

      expect(_.isFunction(->)).true

  describe "#isValidator", ->
    it "checks if the object is a validator", ->
      expect(_.isValidator({test: ->})).true
      expect(_.isValidator({test: null})).false
      expect(_.isValidator({})).false
      expect(_.isValidator(null)).false

  describe "#isArray", ->
    it "checks if value is a list", ->
      expect(_.isArray(undefined)).false
      expect(_.isArray(null)).false
      expect(_.isArray(false)).false
      expect(_.isArray(true)).false
      expect(_.isArray({})).false
      expect(_.isArray("string")).false
      expect(_.isArray(arguments)).false
      expect(_.isArray([])).true

  describe "#isValidationError", ->
    it "checks if a value is an ValidationError", ->
      expect(_.isValidationError(new ValidationError())).true
      expect(_.isValidationError(new Error())).false
      expect(_.isValidationError({})).false

  describe "#guardValidator", ->
    it "raises an error if the given argument is not validator", ->
      expect(-> _.guardValidator(null)).throw('null is not a valid validator')

    it "does nothing when it's valid", (validator) ->
      expect(-> _.guardValidator(validator)).not.throw()

  describe "#guardValidationError", ->
    it "throws the error if it's not a validation error", ->
      expect(-> _.guardValidationError(new Error('boom'))).throw('boom')

    it "doesn't throw an error if it's a ValidationError", ->
      expect(-> _.guardValidationError(new ValidationError())).not.throw()

    it "doesn't throw an error if it's a ValidationError descendent", ->
      class CustomValidationError extends ValidationError

      expect(-> _.guardValidationError(new CustomValidationError())).not.throw()

  describe "#contains", ->
    it "test if an element is present on a list", ->
      expect(_.contains([], 1)).false
      expect(_.contains([1], 1)).true
      expect(_.contains([0, 1, 2], 0)).true
      expect(_.contains([0, 1, 2], 1)).true
      expect(_.contains([0, 1, 2], 2)).trueQ
      expect(_.contains([0, 1, 2], 3)).false

  describe "#map", ->
    it "maps a list into another", ->
      expect(_.map([1, 2, 3], (x) -> x * 2)).eql [2, 4, 6]

  describe "#reduce", ->
    it "reduces the list into a value", ->
      expect(_.reduce([1, 2, 3], 0, (acc, x) -> x + acc)).eq 6

  describe "#lift", ->
    describe "dealing with values", ->
      it "converts the return into a promise", ->
        fn = (input) -> "#{input}-value"

        _.lift(fn)('in').then (value) ->
          expect(value).eq 'in-value'

      it "raises a rejected promise when the function throw an error", ->
        fn = -> throw new Error('err')

        expect(_.lift(fn)()).hold.reject('err')

    describe "dealing with promises", ->
      it "returns a promise if it's already one", ->
        fn = -> Promise.resolve('value')

        _.lift(fn)().then (value) ->
          expect(value).eq 'value'

      it "raises a rejected promise when the given promise is failed throw an error", ->
        fn = -> Promise.reject(new Error('err'))

        expect(_.lift(fn)()).hold.reject('err')

  describe "#humanizeFieldName", ->
    it "transforms the field name a more human form", ->
      expect(_.humanizeFieldName('')).eq ''
      expect(_.humanizeFieldName('Name')).eq 'Name'
      expect(_.humanizeFieldName('name')).eq 'Name'
      expect(_.humanizeFieldName('NAME')).eq 'Name'
      expect(_.humanizeFieldName('password_confirmation')).eq 'Password confirmation'
