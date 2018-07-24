# T-SQL Fundamentals
## Chapter 1 Background to T-SQL Querying and Programming
### Theoretical Background
- SQL stands for *Structured Query Language*.
- An RDBMS, relational database management system, is a database management system based on the relational model, which in turn is based on 2 mathematical branches: set theory and predicate logic.
- SQL is a standard language that was designed to query and manage data in RDBMS.
- Microsoft provides T-SQL as a dialect of SQL in Microsoft SQL Server data management software.

#### SQL
- SQL is both an ANSI and ISO standard language. It resembles English and is also very logical.
- SQL has several categories of statements:
  - DDL (Data definition language) deals with object definition: CREATE, ALTER, DROP.
  - DML (Data management language) allows you to query and modify data: SELECT, INSERT, UPDATE, DELETE, TRUNCATE, MERGE.
  - DCL (Data control language) deals with permissions: GRANT, REVOKE.

#### Set Theory
> By a "set" we mean any collection M into a whole of definite, distinct objects m (which are called the "elements" of M) of our perception or our thought. -- Joseph W. Dauben and Georg Cantor

- *whole*: a set should be considered as a single entity. Your focus should be on the collection of objects as opposed to the individual objects that make up the collection.
- *distinct*: every element of a set must be unique. Without a key, you won't be able to uniquely idenfity rows, and therefore the table won't qualify as a set. Rather, the table would be a multiset or bag.  
- *of our perception or of our thought*: the defition of a set is subjective. When you design a data model, the design process should carefully consider the subjective needs of the application to determine adequate definitions for the entities involved.
- Notice that the definition doesn't mention any order among the set elements. The order in which set elements are listed is not important.

#### Predicate Logic
Loosely speaking, a predicate is a property or an expression that either holds or doesn't hold -- in other words, is either true or false.
- The relational model relies on predicates to maintain the logical integrity of the data and defines its structure.
- You can use predicates when filtering data to define subsets.
- In set theory, you can use predicate to define sets.

#### The Relational Model
The relational model is a semantic model for data management and manipulation and is based on set theory and predicate logic.
- The goal of the relational model is to enable consistent representation of data with minimal or no redundancy and without sacrificing completeness, and to define data integrity (enforcement of data consistency) as part of the model.
- An RDMBS is supposed to implement the relational model and provide the means to store, manage, enforce the integrity of, and query data.

##### Propositions, Predicates, and Relations
