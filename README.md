composed-validations
====================

[![Build Status](https://drone.io/github.com/wilkerlucio/composed-validations/status.png)](https://drone.io/github.com/wilkerlucio/composed-validations/latest)

Javascript validation library that makes sense.

Index
-----

- [Introduction](#introduction)
- [Install](#install)
- [Basic Validations](#basic-validations)
- [Async Validations](#async-validations)
- [Composing Validations](#composing-validations)
- [Built-in validators](#built-in-validators)
  - [Leaf Validators](#leaf-validators)
    - [PresenceValidator](#presencevalidator)
    - [FormatValidator](#formatvalidator)
    - [RangeValidator](#rangevalidator)
    - [IncludeValidator](#includevalidator)
  - [Multi Validators](#multi-validators)
    - [MultiValidator](#multivalidator)
    - [StructValidator](#structvalidator)
  - [Delegational Validators](#delegational-validators)
    - [FieldValidator](#fieldvalidator)
    - [NegateValidator](#negatevalidator)
    - [AllValidator](#allvalidator)
    - [RephraseValidator](#rephrasevalidator)
- [Creating custom validators](#creating-custom-validators)
  - [Creating synchronous validators](#creating-synchronous-validators)
  - [Creating asynchronous validators](#creating-asynchronous-validators)
- Case Study: validating user signup on server and client side with same configuration

Introduction
------------

Before we see any code, I would first like to explain the basis of `composed-validations`.

The entire framework works around a really simple interface, remember that, it is:

```javascript
validator.test(value);
```

All of the validators responds to this interface, and each validator is a single small piece that just validates a
single value. In order to validate complex values, you use `compositional validators` that will compose your complex
validation.

Install
-------

Currently we ship the library in two formats, you can use the `NPM` version:

```
npm install -S composed-validations
```

Or you can [download the browser version](https://raw.githubusercontent.com/wilkerlucio/composed-validations/master/composed-validations.js)

Basic validations
-----------------

Let's start with the simplest validations that just checks if a value is present:

```javascript
var validations = require('composed-validations');

var validator = new validations.PresenceValidator()

validator.test(null); // will raise a ValidationError, since null is not a present value
validator.test('ok'); // will just not raise any errors, since it's valid
```

And let's look at one more, just for the sake of exemplify:

```javascript
var validations = require('composed-validations');

var validator = new validations.RangeValidator(10, 20)

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
be built-in. But it's pretty easy to implement your own, check the (creating async validators)[] section for more info
on that.

The point here is just to have you know about validators may return a `Promise` instead of raising the error right away.

We don't provide async validators, but we provide some mechanims for you to use them, we will talk more about that later
on this doc.

If you are not familiar with the `Promise` concept, this is a good place to start: [https://www.promisejs.org](https://www.promisejs.org)

Composing Validations
--------------------

Ok, now that you got the basics, let's go a step further, we are going to get into object fields validations, but before
that, let's first understand what "complex multi-field validations" are about; what happens when you do a complex
validation is actually just having many validations that runs togheter. And for multi validations running togheter,
let's introduce the `MultiValidator`:

```javascript
var val = require('composed-validations'),
    PresenceValidator = val.PresenceValidator,
    IncludeValidator = val.IncludeValidator,
    MultiValidator = val.MultiValidator;

var validator = new MultiValidator()
  .add(new PresenceValidator())
  .add(new IncludeValidator(['optionA', 'optionB']);

validator.test(null); // will raise an error that has information from both failures
```

The example above is silly because the IncludeValidator would reject the null anyway, but I hope you understand the
point being made, that is, you can have multiple validations happening togheter into a given value. So, what about
objects? Objects are just values as strings, lists or any other... We just need a way to target specific parts of the
object, and for that we have the `FieldValidator`:

```javascript
var val = require('composed-validations'),
    PresenceValidator = val.PresenceValidator,
    FieldValidator = val.FieldValidator;

// let's create a PresenceValidator, that is wrapped by a FieldValidator
var validator = new FieldValidator('name', new PresenceValidator());

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
var val = require('composed-validations'),
    PresenceValidator = val.PresenceValidator,
    FieldValidator = val.FieldValidator,
    MultiValidator = val.MultiValidator;

var validator = new MultiValidator()
  .add(new FieldValidator('name', new PresenceValidator())
  .add(new FieldValidator('email', new PresenceValidator());

validator.test({name: "cgp", email: "hello@internet.com"});
```

Nice hum? Both you are probably thinking "oh boy it's verbose"... And we agree, also, this generic way of handling
fields is great in terms of extensibility, but is not very friendly when you trying to get information about problems
on specific fields, or if you want to run tests on a single field instead of running them all. And that's why the
`MultiValidator` is just the beginning, there are other more specific "multi-validation" classes to help you out. For
now let's take a look at the one you probably gonna use the most, the `StructValidator`:

```javascript
var val = require('composed-validations'),
    PresenceValidator = val.PresenceValidator,
    StructValidator = val.StructValidator;

var addressValidator = new StructValidator()
  .validate('street', new PresenceValidator())
  .validate('zip', new FormatValidator(/\d{5}/) // silly zip format
  .validate('city', new PresenceValidator())
  .validate('state', new PresenceValidator());

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
var val = require('composed-validations'),
    PresenceValidator = val.PresenceValidator,
    IncludeValidator = val.IncludeValidator,
    StructValidator = val.StructValidator;

// let's say this will import the validator from the previous example
addressValidator = require('./address_validator');

userValidator = new StructValidator();
  .validate('name', new PresenceValidator())
  .validate('age', new RangeValidator(0, 200))
  .validate('userType', new IncludeValidator(['member', 'admin']))
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

[Source](https://github.com/wilkerlucio/composed-validations/blob/master/lib/validators/presence_validator.coffee)

This validator with check if the given value is present.

### Constructor

```javascript
new PresenceValidator();
```

### Example

```javascript
var validator = new PresenceValidator();

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

[Source](https://github.com/wilkerlucio/composed-validations/blob/master/lib/validators/format_validator.coffee)

This validator tests a value against a [Regular Expression](https://developer.mozilla.org/en/docs/Web/JavaScript/Guide/Regular_Expressions).

### Constructor

```javascript
new FormatValidator(RegExp format);
```

### Example

```javascript
var validator = new FormatValidator(/\d+/);

validator.test('ab12'); // ok
validaotr.test('abc'); // error! doesn't match the format!
```

IncludeValidator
-----------------

[Source](https://github.com/wilkerlucio/composed-validations/blob/master/lib/validators/include_validator.coffee)

This validator tests a value against a pre-defined list of options.

### Constructor

```javascript
new IncludeValidator(Array options);
```

### Example

```javascript
var validator = new IncludeValidator(['one', 'two']);

validator.test('one'); // ok
validator.test('two'); // ok
validator.test('three'); // error, three is not included on the options
```

RangeValidator
---------------

[Source](https://github.com/wilkerlucio/composed-validations/blob/master/lib/validators/range_validator.coffee)

This validator if a value is included into a given range.

### Constructor

```javascript
new RangeValidator(min, max);
```

Remember that `min` and `max` can be pretty much anything, it will work on numbers, but also on strings.

The validator will raise an error on construction if you your `min` is bigger than `max`.

### Example

```javascript
var validator = new RangeValidator(-3, 12);

validator.test(-3); // ok, still on the range
validator.test(-4); // error
validator.test(5); // ok
validator.test(13); // error
```

Multi Validators
----------------

MultiValidator
---------------

This validator enables you to create a group of validations that will run in order to validate a single value.

### Constructor

```javascript
new MultiValidator({
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

### Registerind validators

#### `add(validator)`

This function will register a new validator in the list of validators that are going to run. Remember that all child
validators will run, what I mean is, it will not stop on the first failure, when a failure occurs it will register it
and keep going to run the rest of the validators, in the end, if there are errors, all of them will be available for
you into the error object (also, in case of async, the validators will run in parallel).

### Example

A sync example:

```javascript
var validator = new MultiValidator();

validator.add(new MinValidator(2));
validator.add(new MaxValidator(5));

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
var validator = new MultiValidator({async: true});

validator.add(new PresenceValidator());
validator.add(new SomeAsyncValidator());

validator.test(function() {
  // all ok, do your thing
}, function(err) {
  err.message; // a message combining the errors descriptions, good for debug, bad for showing to the user
  err.errors; // a list with each error raised from the validators
});
```

StructValidator
----------------

This validator is an extension of the [MultiValidator](#multivalidator), it has all the features available there, plus
a few more.

### Constructor

```javascript
new StructValidator({
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
validator.validate('name', new PresenceValidator);
validator.test({name: "someone"});
validator.testField('name'); // will also run the test
```

#### `addAssociated(field..., validator)`

It works almost as same as `validate`, expect that it **will not** wrap the validator with a `FieldValidator`.

```javascript
// this will end up as same as the previous validate example
validator.addAssociated('name', new FieldValidator('name', new PresenceValidator));
validator.test({name: "someone"});
validator.testField('name', {name: "someone"}); // will also run the test
```

#### `addFieldValidator(field..., validator)`

It is like `addAssociated` except that it **will not** add the validator into the regular validators list, that means
the validator will only be called when you ask to validate that specific field, but no the general validation.

```javascript
validator.addFieldValidator('name', new FieldValidator('name', new PresenceValidator));
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
var validator = new StructValidator({async: true});

validator.validate('name', 'username', new PresenceValidator());
validator.validate('username', uniqUserNameValidator); // lets say this validator does an ajax call to verify if the user name is available

// when calling the testField you must pass the entire object to value (not just the value of the field), the reason
// for that is because there are some validators that runs a given a field but also needs information from other fields,
// a "password confirmation" validator would be the most common example of that case
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
var passwordMatchValidator = {
  test: (value) {
    if (value.password != value.password_confirmation) {
      throw new ValidationError("Password confirmation doesn't match the password", value, this);
    }
  }
};

var userValidator = new StructValidator();

userValidator.validate('name', 'password', new PresenceValidator());
userValidator.validate('email', new FormatValidator(/\w+@\w+\.\w+/));
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

Delegational Validators
-----------------------

DelegationalValidator
----------------------

FieldValidator
---------------

NegateValidator
----------------

AllValidator
-------------

RephraseValidator
-----------------


Warning
-------

This library and it's documentation are in active development and design, and can still change a lot. Stay tuned.
