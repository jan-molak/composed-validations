composed-validations
====================

[![Build Status](https://drone.io/github.com/wilkerlucio/composed-validations/status.png)](https://drone.io/github.com/wilkerlucio/composed-validations/latest)

Javascript validation library that makes sense.

Index
-----

- [Introduction](#introduction)
- [Basic Validations](#basic-validations)
- [Async Validations](#async-validations)
- [Composit Validations](#composit-validations)
- [Built-in validators](#built-in-validators)
  - Leaf validators
    - PresenceValidator
    - RangeValidator
    - IncludeValidator
    - TypeValidator
    - InstanceOfValidator
  - Compositional validators
    - NegateValidator
    - FieldValidator
    - MultiValidator
    - ListValidator
    - MultifieldValidator
- Creating custom validators
  - creating sync validators
  - creating async validators
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

Composit Validations
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

var validator = new MultiValidator();
validator.add(new PresenceValidator());
validator.add(new IncludeValidator(['optionA', 'optionB']);

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
  .add('street', new PresenceValidator())
  .add('zip', new FormatValidator(/\d{5}/) // silly zip format
  .add('city', new PresenceValidator())
  .add('state', new PresenceValidator());

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
userValidator.add('name', new PresenceValidator());
userValidator.add('age', new RangeValidator(0, 200));
userValidator.add('userType', new IncludeValidator(['member', 'admin']));
// in fact, the address validator is just another composed validator, so just send it!
userValidator.add('address', addressValidator);

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

Warning
-------

This library and it's documentation are in active development and design, and can still change a lot. Stay tuned.
