composed-validations
====================

[![Build Status](https://drone.io/github.com/composed-validations/composed-validations/status.png)](https://drone.io/github.com/composed-validations/composed-validations/latest)

Javascript validation library that makes sense.

Index
-----

- [Introduction](#introduction)
- [Install](#install)
- [Basic Validations](#basic-validations)
- [Async Validations](#async-validations)
- [Composing Validations](#composing-validations)
- [Creating custom validators](#creating-custom-validators)
  - [Creating synchronous validators](#creating-synchronous-validators)
  - [Creating asynchronous validators](#creating-asynchronous-validators)
- [Built-in validators](#built-in-validators)
  - [Leaf Validators](#leaf-validators)
    - [PresenceValidator](#presencevalidator)
    - [FormatValidator](#formatvalidator)
    - [RangeValidator](#rangevalidator)
    - [IncludeValidator](#includevalidator)
  - [Multi Validators](#multi-validators)
    - [MultiValidator](#multivalidator)
    - [StructValidator](#structvalidator)
    - [SequenceValidator](#sequencevalidator)
  - [Delegational Validators](#delegational-validators)
    - [FieldValidator](#fieldvalidator)
    - [NegateValidator](#negatevalidator)
    - [AllValidator](#allvalidator)
    - [RephraseValidator](#rephrasevalidator)
- [Helper Library](#helper-library)
  - [json(value)](#jsonvalue)
  - [isString(value)](#isstringvalue)
  - [isFunction(value)](#isfunctionvalue)
  - [isArray(value)](#isarrayvalue)
  - [isValidator(value)](#isvalidatorvalue)
  - [guardValidator(value)](#guardvalidatorvalue)
  - [guardValidationError(value)](#guardvalidationerrorvalue)
  - [contains(list, value)](#containslist-value)
  - [map(list, iterator)](#maplist-iterator)
  - [reduce(list, initial, iterator)](#reducelist-initial-iterator)
  - [lift(function)](#liftfunction)
  - [humanizeFieldName(name)](#humanizefieldnamename)
- [More Information](#more-information)

Introduction
------------

Before we see any code, I would first like to explain the basis of `composed-validations`.

The entire framework works around a really simple interface, remember that, it is:

```javascript
validator.test(value);
```

All of the validators responds to this interface, and each validator is a single small piece that just validates a
single value. In order to validate complex values, you use `compositional validators` that will compose your complex
validation. We will learn more about that though this documentation.

Install
-------

Currently we ship the library in two formats, you can use the `NPM` version:

```
npm install -S composed-validations
```

Or you can [download the browser version](https://raw.githubusercontent.com/composed-validations/composed-validations/master/composed-validations.js)
(it's about 5kb when minified+gzip).

Basic validations
-----------------

Let's start with the simplest validations that just checks if a value is present:

```javascript
var cv = require('composed-validations');

var validator = cv.presence()

validator.test(null); // will raise a ValidationError, since null is not a present value
validator.test('ok'); // will just not raise any errors, since it's valid
```

And let's look at one more, just for the sake of exemplify:

```javascript
var cv = require('composed-validations');

var validator = cv.range(10, 20)

validator.test(9); // will raise a ValidationError, since null is out of range
validator.test(10); // will just not raise any errors, since it's valid
validator.test(15); // will just not raise any errors, since it's valid
validator.test(25); // will raise a ValidationError, since null is out of range
```

So, each validator should be constructed and configured, and them it will just respond to the `test` when it's called.

The examples above are really simple ones, so, let's get into the composed validators on the next section.

Async Validations
-----------------

The async validations works pretty much the same way as sync validations, the only difference is that instead of
throwing the error right away, it will must return a `Promise`, that can resolve (we don't care on what) or get rejected
(when the validation fails).

Right now we don't provide any async validators out of the box because I couldn't find any general ones that worth to
be built-in. But it's pretty easy to implement your own, check the [Creating asynchronous validators](#creating-asynchronous-validators) section for more info
on that.

The point here is just to have you know about validators may return a `Promise` instead of raising the error right away.

We don't provide async validators, but we provide some mechanims for you to use them, we will talk more about that later
on this doc.

If you are not familiar with the `Promise` concept, this is a good place to start: [https://www.promisejs.org](https://www.promisejs.org)

Composing Validations
---------------------

Ok, now that you got the basics, let's go a step further, we are going to get into object fields validations, but before
that, let's first understand what "complex multi-field validations" are about; what happens when you do a complex
validation is actually just having many validations that runs togheter. And for multi validations running togheter,
let's introduce the `MultiValidator`:

```javascript
var cv = require('composed-validations');

var validator = cv.multi()
  .add(cv.presence())
  .add(cv.include(['optionA', 'optionB']);

validator.test(null); // will raise an error that has information from both failures
```

The example above is silly because the IncludeValidator would reject the null anyway, but I hope you understand the
point being made, that is, you can have multiple validations happening togheter into a given value. So, what about
objects? Objects are just values as strings, lists or any other... We just need a way to target specific parts of the
object, and for that we have the `FieldValidator`:

```javascript
var cv = require('composed-validations');

// let's create a PresenceValidator, that is wrapped by a FieldValidator
var validator = cv.field('name', cv.presence());

validator.test(null); // will raise an error because it cannot access fields on falsy values
validator.test({age: 15}); // will raise an error because the field 'name' is not present on the object
validator.test({name: null}); // this time it will fail because the PresenceValidator will not allow the null
validator.test({name: "Mr White"}); // you think it will pass? "You are god damn right!"
```

So, know we know 2 things:

1. We can run multiple validations togheter
2. We can use FieldValidator to validates specific fields on the object

Do the math, and you will realise you can validate complex objects as:

```javascript
var cv = require('composed-validations');

var validator = cv.multi()
  .add(cv.field('name', cv.presence())
  .add(cv.field('email', cv.presence());

validator.test({name: "cgp", email: "hello@internet.com"});
```

Nice hum? Both you are probably thinking "oh boy it's verbose"... And we agree, also, this generic way of handling
fields is great in terms of extensibility, but is not very friendly when you trying to get information about problems
on specific fields, or if you want to run tests on a single field instead of running them all. And that's why the
`MultiValidator` is just the beginning, there are other more specific "multi-validation" classes to help you out. For
now let's take a look at the one you probably gonna use the most, the `StructValidator`:

```javascript
var cv = require('composed-validations');

var addressValidator = cv.struct()
  .validate('street', cv.presence())
  .validate('zip', cv.format(/\d{5}/) // silly zip format
  .validate('city', cv.presence())
  .validate('state', cv.presence());

addressValidator.test({
  street: 'street name',
  zip: '51235',
  city: 'Tustin',
  state: 'CA'
}); // test all!

addressValidator.testField('street'); // this will run only the tests that targets the 'street' field
```

The `StructValidator` is just an extension of `MultiValidator` you can still use the regular `add` method, it's just
that `StructValidator` wraps a lot of knowledge about `struct` type data, so it will do the hard work so you don't have
to.

And going further to make sure you understand the power of composing validations, check this out:

```javascript
var cv = require('composed-validations');

// let's say this will import the validator from the previous example
addressValidator = require('./address_validator');

userValidator = cv.struct();
  .validate('name', cv.presence())
  .validate('age', cv.range(0, 200))
  .validate('userType', cv.include(['member', 'admin']))
  // in fact, the address validator is just another composed validator, so just send it!
  .validate('address', addressValidator);

userValidator.test({
  name: 'The Guy',
  age: 26,
  userType: 'admin',
  address: {
    street: 'street name',
    zip: '51235',
    city: 'Tustin',
    state: 'CA'
  }
}); // and there you have it, all validations will go into the right places!
```

And that's what composed validations is about, there still a lot that wasn't covered here, things like mixing sync and
async validations into multi validators, making fields optional, replacing error messages... Oh boy that's still a lot
that you can know about this library, check each validator specific documentation for details on each feature for more
details.

Creating custom validators
--------------------------

Creating synchronous validators
-------------------------------

Being able to add custom validators is something that I really care about, the framework
was designed and built upon a simple interface in order to make as easy as possible to
create new validators and use it togheter with others.

Remember the interface that we talked about on the introduction?

```javascript
validator.test(value)
```

I mean it, so, let's implement a simple validator that validates if a value is equal
to a specific value. And let's do it into the simplest possible way:

```javascript
var cv = require('custom-validations');

var equalToHelloValidator = {
  test: function(value) {
    if (value != 'hello') {
      throw cv.error('is not equal to hello', value, this);
    }

    // you must return the same input as given to you, unless you are writing a
    // specifically to transform the data
    return value;
  }
};

// using the validator
equalToValidator.test('not'); // faill
equalToValidator.test('hello'); // ok
```

As you see, the only thing that we need from `custom-validations` is the
`ValidationError`, the reason why you must use it to fire errors instead of a regular
error, is because that way we can differentiate validation errors from other kinds of
errors (that would be handle in different ways). The signature for instantiating a new
`ValidationError` is:

```javascript
cv.error(message, value, validator);
```

This information helps other validators and errors handlers to deal better with error
information.

After you have it, just another quick example on how to use it with the regular
validators:

```javascript
var cv = require('custom-validations');

var equalToHelloValidator = {
  test: function(value) {
    if (value != 'hello') {
      throw cv.error('is not equal to hello', value, this);
    }
  }
};

var modelValidator = cv.struct()
  .validate('someField', equalToHelloValidator);

modelValidator.test({someField: 'hello'}); // ok
```

You usually want a bit of more flexibility, but that's easy to accomplish, instead of
making our validator as a crude object, we can use a factory to generate it in a more
customizable way, as so:

```javascript
var cv = require('composed-validations');

var equalToValidator = function (given) {
  return {
    test: function(value) {
      if (value != given) {
        throw cv.error("is not equal to " + JSON.stringify(given), value, this);
      }
    }
  };
};

var modelValidator = cv.struct()
  .validate('someField', equalToValidator('hello'));

modelValidator.test({someField: 'hello'}); // ok
```

I love the power of closures, don't you?

You can use class style if you prefer:

```javascript
var cv = require('composed-validations');

var EqualToValidator = function (given) {
  this.given = given;
};

EqualToValidator.prototype.test = function(value) {
  if (value != this.given) {
    throw cv.error("is not equal to " + JSON.stringify(this.given), value, this);
  }
};

var modelValidator = cv.struct()
  .validate('someField', new EqualToValidator('hello'));

modelValidator.test({someField: 'hello'}); // ok
```

As you can see, it doesn't matter how you decide to build/construct/initialize your
validators, the only thing that matters is that in the end you have an object that
responds to:

```javascript
validator.test(value);
```

And them it will happily blend into the system.

Creating asynchronous validators
--------------------------------

Asynchronous validators implementation is pretty much the same as regular validations,
there are only 2 differences that you need to be aware of:

1. Asynchronous validators must respond to the method `async` returning `true`
2. Asynchronous validators must always returns a `Promise/A` compliant `Promise`

You can use any `Promises/A` compliant library to get your promises (when, Q, Promise...)
but since we needed to have one internally, and some users may not want to add another
dependency, we expose our internal instance of the [Promise](https://www.npmjs.org/package/promise) library for you, so you
can just use it if you want.

Let's go for an example:

```javascript
var cv = require('composed-validations'),
    Promise = cv.Promise;

var delayedValidator = {
  // this is very important, because some validators have different ways of running
  // when composed with async, don't forget it!
  async: function() { return true; };

  test: function(value) {
    // get a hold of this, we gonna need it
    var _this = this;

    return new Promise(function(resolve, reject) {
      setTimeout(function() {
        if (value == 'hello') {
          // if it's ok, you can resolve with anything, it doesn't really matter
          resolve(null);
        } else {
          // when error happens, raise it! promises style
          reject(cv.error("is not equal to hello", value, _this);
        }
      }, 500);
    });
  }
};

delayedValidator.test('fail').then(function() {
  // all good, but with the argument that will passed, here will not be reached
}, function(err) {
  // your error handling
});
```

One of the reasons that you have to explicitly say that your validator is async, is to
protect you on situations like this:

```javascript
cv.struct() // note this is a "sync" kind of multi validator
  .validate('name', cv.presence()) // ok, presence if sync
  .validate('hello', delayedValidator); // this will raise an error!
```

Think about it, it's totally possible to convert `sync` validators into an `async` form,
but it's impossible on the other direction. So, if you add an `async` validator into a
`sync` multi validator (remember that `StructValidator` is just a specialized type of
`MultiValidator`) you probably did by mistake, so the library will raise an error and
ask you to make your multi validator `async`:

```javascript
cv.struct({async: true})
  .validate('name', cv.presence())
  .validate('hello', delayedValidator); // now it's all fine
```

Built-in Validators
-------------------

This section documents each single validator on the framework.

First, I'll give you the picture of what the class struct looks like:

![Composed Validations Diagram](https://dl.dropboxusercontent.com/u/1772210/composed_validations.png)

For the documentation, we gonna separate the validators in three categories:

- [Leaf Validators](#leaf-validators): those are the validators that operates on most simple values
- [Multi Validators](#multi-validators): those are structural validators that helps you to do multiple validations at once
- [Delegational Validators](#delegational-validators): those are structural validators that will take one other validator and do some kind of structuring on the validator's behavior

Leaf Validators
---------------

PresenceValidator
------------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/presence_validator.coffee)

This validator with check if the given value is present.

### Constructor

```javascript
cv.presence();
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.presence();

// those will throw an error
validator.test(undefined);
validator.test(false);
validator.test(null);
validator.test("");
validator.test("   "); // empty spaces still count as blank

// those are valid, and will not throw an error
validator.test("ok");
validator.test({});
```

FormatValidator
----------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/format_validator.coffee)

This validator tests a value against a [Regular Expression](https://developer.mozilla.org/en/docs/Web/JavaScript/Guide/Regular_Expressions).

### Constructor

```javascript
cv.format(RegExp format);
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.format(/\d+/);

validator.test('ab12'); // ok
validaotr.test('abc'); // error! doesn't match the format!
```

IncludeValidator
-----------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/include_validator.coffee)

This validator tests a value against a pre-defined list of options.

### Constructor

```javascript
cv.include(Array options);
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.include(['one', 'two']);

validator.test('one'); // ok
validator.test('two'); // ok
validator.test('three'); // error, three is not included on the options
```

RangeValidator
---------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/range_validator.coffee)

This validator if a value is included into a given range.

### Constructor

```javascript
cv.range(min, max);
```

Remember that `min` and `max` can be pretty much anything, it will work on numbers, but also on strings.

The validator will raise an error on construction if the `min` value is greater than `max`.

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.range(-3, 12);

validator.test(-3); // ok, still on the range
validator.test(-4); // error
validator.test(5); // ok
validator.test(13); // error
```

Multi Validators
----------------

MultiValidator
---------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/multi_validator.coffee)

This validator enables you to create a group of validations that will run in order to validate a single value.

### Constructor

```javascript
cv.multi({
  async: false
});
```

The object with the options on constructor is optional.

Available options:

- `async`: if you have ANY async validators into your `MultiValidator` you must pass this option as `true`, otherwise
when you try to add an `async` validator it will raise an error. The reason for that is that in order to mix sync and
async validators, we must convert all the validators to an async form, also, it changes the way the errors are thrown.
When you do a sync validation it will throw the errors right way, on the async scenario they will be dispatched as
`Promise` errors. This flag is to prevent you to use the wrong interface by mistake, so, if you need async on your
`MultiValidator`, send it as `true`.

### Registering validators

#### `add(validator)`

This function will register a new validator in the list of validators that are going to run. Remember that all child
validators will run, what I mean is, it will not stop on the first failure, when a failure occurs it will register it
and keep going to run the rest of the validators, in the end, if there are errors, all of them will be available for
you into the error object (also, in case of async, the validators will run in parallel).

### Example

A sync example:

```javascript
var cv = require('composed-validations');
var validator = cv.multi();

// pretend those validators exists for now, they may in future
validator.add(minValidator(2));
validator.add(maxValidator(5));

validator.test(2); // ok

try {
  validator.test(-1);
} catch (err) {
  err.message; // a message combining the errors descriptions, good for debug, bad for showing to the user
  err.errors; // a list with each error raised from the validators
}
```

An async example:

```javascript
var cv = require('composed-validations');
var validator = cv.multi({async: true});

validator.add(cv.presence());
validator.add(someAsyncValidator());

validator.test(function() {
  // all ok, do your thing
}, function(err) {
  err.message; // a message combining the errors descriptions, good for debug, bad for showing to the user
  err.errors; // a list with each error raised from the validators
});
```

StructValidator
---------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/struct_validator.coffee)

This validator is an extension of the [MultiValidator](#multivalidator), it has all the features available there, plus
a few more.

### Constructor

```javascript
cv.struct({
  async: false
});
```

The options are optional, for details on the async option see [MultiValidator](#multivalidator).

### Registering validators

While you still have the `add` option, these are a few new options that you have to add validators and link them with
specific fields on a struct:

#### `validate(field..., validator)`

Registers a validator for a given field, and it will automatically wrap the given validator with a [FieldValidator](#fieldvalidator)
associated with the same given field. It register the validator on two lists, the basic validators list (that will run
when you call `test`) and also into the field validators list (check `testField` method for more info).

This is probably the method that you will use the most, because it address the most common situation (adding a validator
to validates the data on a field).

```javascript
validator.validate('name', cv.presence());
validator.test({name: "someone"});
validator.testField('name'); // will also run the test
```

#### `addAssociated(field..., validator)`

It works almost as same as `validate`, expect that it **will not** wrap the validator with a `FieldValidator`.

```javascript
// this will end up as same as the previous validate example
validator.addAssociated('name', cv.field('name', cv.presence()));
validator.test({name: "someone"});
validator.testField('name', {name: "someone"}); // will also run the test
```

#### `addFieldValidator(field..., validator)`

It is like `addAssociated` except that it **will not** add the validator into the regular validators list, that means
the validator will only be called when you ask to validate that specific field, but no the general validation.

```javascript
validator.addFieldValidator('name', cv.field('name', cv.presence()));
validator.test({name: "someone"}); // this will not trigger any validators
validator.testField('name', {name: "someone"}); // this will run the registered validator for the field
```

### Running validators for a single field

`StructValidator` makes also possible to only the validators associated with a given field, that can save a lot of work,
specially if have some field that uses a resourceful async option, that way on live forms when user updates an input you
can run only the validators for that given field.

Remember that the behavior is same as the `test` method on the regard of sync/async operations, if you use the flag
`async: true` it will return a promise, otherwise will throw an error in case of failure.

How to use it:

```javascript
var cv = require('composed-validations');
var validator = cv.struct({async: true});

validator.validate('name', 'username', cv.presence());
// lets say this validator does an ajax call to verify if the user name is available
validator.validate('username', uniqUserNameValidator);

// when calling the testField you must pass the entire object to value (not just the
// value of the field), the reason for that is because there are some validators that
// runs a given a field but also needs information from other fields, a
// "password confirmation" validator would be the most common example of that case
validator.testField('name', {name: "", username: ""}).done(function() {
  // the field is fine, do your UI stuff
}, function(err) {
  // err here is a MultiValidationError, as same as the error on the MultiValidator

  var errors = err.errors; // list of errors from the test on that field
  // do your UI updates
});
```

### Example

```javascript
var cv = require('composed-validations');

var passwordMatchValidator = {
  test: (value) {
    if (value.password != value.password_confirmation) {
      throw cv.error("Password confirmation doesn't match the password", value, this);
    }
  }
};

var userValidator = cv.struct();

userValidator.validate('name', 'password', cv.presence());
userValidator.validate('email', cv.format(/\w+@\w+\.\w+/));
userValidator.addAssociated('password_confirmation', passwordMatchValidator);

try {
  userValidator.validate({
    name: "",
    email: "invalid",
    password: "123"
  });
} catch (err) {
  err.errors; // a list will all errors
  err.fieldErrors.name // errors on the field name, if there were no errors, will be an empty list
}
```

SequenceValidator
-----------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/sequence_validator.coffee)

This validator is another kind of `MultiValidator` but it runs a bit different way.

While `MultiValidator` is concerned about running all the available validators as quick
as possible, and them grouping the errors results, the `SequenceValidator` instead runs
the validators one by one, and if any validation error occurs, it will stop the
iteration and throw that error right way.

This behavior is good when you have a slow validation that can be prevented to run when
a quicker one can detect the fail first, for example, if you have a validator that
hits the server and verify if a given email is already registered on the database, this
validation is considered slow because it needs to go into a server, which can take a
while, but in the email case, you can prevent it from running if you verify that the
email is on an invalid format, that way the format validator can prevent the uniq
validator to run until the email format is at least valid.

Another difference on `SequenceValidator` is that on it, it's possible to transform the
given value for the next validator. That enables possibilities like a `HttpValidator`
that will fetch data into a server, and them send it to the next validator that will
work on the returned value.

For that matter, **ALL** of the built-in validators will always return the same input
that is given to them, when writing validators you must do that too, unless you really
writing a validator about transforming data.

### Constructor

```javascript
cv.sequence({
  async: false
});
```

The options are optional, for details on the async option see [MultiValidator](#multivalidator).

### Example

```javascript
// let's supposed this is some library that does a request and checks something
var checkRemoteNumber = require('check-remote-number')

var idValidator = cv.sequence({async: true})
  .add(cv.format(\d+))
  .add(checkRemoteNumber);

idValidator.test("ha"); // will fail on the format validator, will not call teh service
idValidator.test("123"); // format ok, checking on the server
```

Delegational Validators
-----------------------

FieldValidator
---------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/field_validator.coffee)

The field validator will run a given validator into a specific field of an object.

### Constructor

```javascript
cv.field(field, validator, {
  optional: false
});
```

Where:

* **field**: the field name
* **validator**: the validator to run the given field
* **options**:
  * **optional**: if true, the validator will accept when the field name is not present
    on the object, (that means, when the object responds false to `hasOwnProperty(field)`)

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.field('name', cv.presence(), {optional: true});

// will fail because it can't access fields on null (same for false or undefined)
validator.test(null);

// will pass, since it's optional and the field is not present
validator.test({});

// will fail because the field is present, so the it will validate the presence, and fail
validator.test({name: null});

// ok
validator.test({name: "chick"});
```

NegateValidator
----------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/negate_validator.coffee)

The negate validator will invert the result of a given validator.

### Constructor

```javascript
cv.negate(validator)
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.negate(cv.presence());

validator.test('hey'); // will fail, inverting the presence validator result
validator.test(null); // ok
```

### Caveats

By a current design constraint, the error messages that comes from `NegateValidator` are
not user friendly... They look like this: `validation negated failed` (all the times).
This is something I plan to improve over time, but for now I suggest you to use the
[RephraseValidator](#rephrasevalidator) to define a better error message for your users.

AllValidator
-------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/all_validator.coffee)

Given the value is a list, runs the validator against of the items, if any item fails
the validation, a `ValidationError` will be thrown.

### Constructor

```javascript
cv.all(validator);
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.all(cv.presence());

validator.test([]); // empty lists give no errors
validator.test([1, null, 'ok']); // fails because null is rejected by PresenceValidator
validator.test(['a', {}, 3]); // all ok here
```

RephraseValidator
-----------------

[Source](https://github.com/composed-validations/composed-validations/blob/master/lib/validators/rephrase_validator.coffee)

Changes the error from a given validator when it fails.

### Constructor

```javascript
cv.rephrase(newMessage, validator)
```

### Example

```javascript
var cv = require('composed-validations');
var validator = cv.rephrase('feed me something true dude...', cv.presence());

try {
  validator.test(null);
} catch (err) {
  err.message; // 'feed me something true dude...'
}
```

Helper Library
--------------

This is me sharing the internals of `composed-validations` with you, I think since they
were useful for me, and you are going to load them anyway, they might be helpful for
you too.

The utility functions listed here are available at the `_` variable into the main
`composed-validations` require (like the good guys [underscore](http://underscorejs.org/) and [lodash](http://lodash.com/):

```javascript
var _ = require('composed-validations')._;
```

On the examples I'll consider that you have the `_` variable set as on the code above.

So here is goes the list of available functions, pick what servers you.

#### `json(value)`

Stringify an object. This is just an alias for `JSON.stringify`

```javascript
_.json('a'); // "a"
```

#### `isString(value)`

Detects if a given `value` is a string.

```javascript
_.isString('a'); // true
_.isString("ab"); // true
_.isString(""); // true
_.isString([]); // false
_.isString(null); // false
_.isString({}); // false
```

#### `isFunction(value)`

Detects if a given `value` is a function.

```javascript
_.isFunction(function() {}); // true
```

#### `isArray(value)`

Detects if a given `value` is an array.

```javascript
_.isArray([]); // true
_.isArray([1, 3]); // true
_.isArray(""); // false
_.isArray({}); // false
```

#### `isValidator(value)`

Detects if a given `value` is a validator (that means, it has a property `test` that is
a `Function`)

```javascript
_.isValidator(cv.presence()); // true
_.isValidator({}); // false
```

#### `guardValidator(value)`

This function will raise an error unless the given `value` is a validator.

#### `guardValidationError(value)`

Will throw an error unless the given `value` is an instance of `ValidationError` (extensions
of the class are also accepted).

#### `contains(list, value)`

Check if `value` is present into the `list`.

```javascript
_.contains([1, 2, 3], 1); // true
_.contains([1, 2, 3], 5); // false
```

#### `map(list, iterator)`

Given a `list`, returns a new `list` by iterating over the elements with the given
`iterator`.

```javascript
_.map([1, 2, 3], function (x) {
  return x * 2;
}; // [2, 4, 6]
```

#### `reduce(list, initial, iterator)`

```javascript
_.reduce([1, 2, 3], 0, function (acc, x) {
  return acc + x;
}); // 6
```

#### `lift(function)`

Given a function, make it returns a rejected `Promise` if any error is thrown, otherwise
returns `Promise` that resolves with the function returned value.

```javascript
var fn = function(x) { return 3 + x; };
var lifted = _.lift(fn);

lifted(2).then(function(z) {
  alert(z); // 5
});
```

#### `humanizeFieldName(name)`

Given a string `name`, converts underlines into spaces and uppercase the first letter.

```javascript
_.humanizeFieldName('name'); // Name
_.humanizeFieldName('password_confirmation'); // Password confirmation
```

More Information
----------------

If you wanna know more tricks and tips about `composed-validations` check our [Wiki Pages](https://github.com/composed-validations/composed-validations/wiki/_pages).
