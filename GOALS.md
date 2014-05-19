# Goals of this project

* Support building web applications with Ruby on Rails or other Rack-based frameworks
    * Support for Rails Views for example
    * Allow Rails developers to get into Guacamole as easy as possible
* Reflect the nature of NoSQL in general and ArangoDB in particular
    * Use the Datamapper pattern, because it allows us to leverage ArangoDB features like nesting in a really nice way
    * Support ArangoDB features like transactions, the query language and graphs

*The two main goals may conflict from time to time.*

## Features of Guacamole 1.0

**This is definitely a moving target and up to discussion. For non-moving targets refer to our [milestones](https://github.com/triAGENS/guacamole/issues/milestones).**

* **Embrace the Multi Model nature of ArangoDB:** It will be possible to connect entities with edges. These edges will have custom classes. It will be possible to do graph queries using these connections.
* **Support for the ArangoDB Query Language:** ArangoDB has a powerful querying language. We want to provide support for it in the most Ruby-way possible. There is already a [discussion about how to do this](https://github.com/moonglum/brazil/issues/8).
* **Support for Transactions:** ArangoDB has support for transactions, we want to make it as easy as possible to use them.
* **Support for Migrations:** Migrations work differently in a database with flexible schema. Some migrations are possible on the fly, but there will still be migrations that need to be executed explicitly. We want to support Rails-like migrations for these types of queries.
* **Support for flexible mapping:** Right now the mapping is very strict, we will allow more flexibility here including renaming or excluding certain attributes.
