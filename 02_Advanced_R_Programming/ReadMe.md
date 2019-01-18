---
title: 'Mastering Software Development in R '
author: "Oleh Yashchuk"
date: '`r format(Sys.time(), "%d/%m/%Y")`'
output:
  html_notebook:
    number_sections: yes
    toc: yes
    toc_depth: 4
  #   df_print: paged
  #   number_sections: yes
  #   toc: yes
  #   toc_depth: '4'
  # html_document:
mainfont: FreeSans
---

# Advanced R Programming

## Debugging and Profiling

### Debugging
This section describes the tools for debugging your software in R. R comes with a set of built-in tools for interactive debugging that can be useful for tracking down the source of problems. These functions are

* browser(): an interactive debugging environment that allows you to step through code one expression at a time
* debug() / debugonce(): a function that initiates the browser within a function
* trace(): this function allows you to temporarily insert pieces of code into other functions to modify their behavior
* recover(): a function for navigating the function call stack after a function has thrown an error
* traceback(): prints out the function call stack after an error occurs; does nothing if there’s no error

#### traceback()
If an error occurs, the easiest thing to do is to immediately call the traceback() function. This function returns the function call stack just before the error occurred so that you can see what level of function calls the error occurred. If you have many functions calling each other in succeeding, the traceback() output can be useful for identifying where to go digging first.

#### browser()
From the traceback output, it is often possible to determine in which function and on which line of code an error occurs. If you are the author of the code in question, one easy thing to do is to insert a call to the browser() function in the vicinity of the error (ideally, before the error occurs). The browser()function takes now arguments and is just placed wherever you want in the function. Once it is called, you will be in the browser environment, which is much like the regular R workspace environment except that you are inside a function.

#### trace()
If you have easy access to the source code of a function (and can modify the code), then it’s usually easiest to insert browser() calls directly into the code as you track down various bugs. However, if you do not have easy access to a function’s code, or perhaps a function is inside a package that would require rebuilding after each edit, it is sometimes easier to make use of the trace() function to make temporary code modifications.

#### debug()
The debug() and debugonce() functions can be called on other functions to turn on the “debugging state” of a function. Callingdebug() on a function makes it such that when that function is called, you immediately enter a browser and can step through the code one expression at a time.

A call to debug(f) where f is a function is basically equivalent totrace(f, browser) which will call the browser() function upon entering the function.

The debugging state is persistent, so once a function is flagged for debugging, it will remain flagged. Because it is easy to forget about the debugging state of a function, the debugonce() function turns on the debugging state the next time the function is called, but then turns it off after the browser is exited.

#### recover()
The recover() function is not often used but can be an essential tool when debugging complex code. Typically, you do not callrecover() directly, but rather set it as the function to invoke anytime an error occurs in code. This can be done via the options()function.

```{r eval=FALSE}
options(error = recover)
```


Usually, when an error occurs in code, the code stops execution and you are brought back to the usual R console prompt. However, when recover() is in use and an error occurs, you are given the function call stack and a menu.

The recover() function is very useful if an error is deep inside a nested series of function calls and it is difficult to pinpoint exactly where an error is occurring (so that you might use browser() ortrace()). In such cases, the debug() function is often of little practical use because you may need to step through many many expressions before the error actually occurs. Another scenario is when there is a stochastic element to your code so that errors occur in an unpredictable way. Using recover() will allow you to browse the function environment only when the error eventually does occur.


### Profiling
#### microbenchmark
The microbenchmark package is useful for running small sections of code to assess performance, as well as for comparing the speed of several functions that do the same thing. The microbenchmarkfunction from this package will run code multiple times (100 times is the default) and provide summary statistics describing how long the code took to run across those iterations. The process of timing a function takes a certain amount of time itself. The microbenchmark function adjusts for this overhead time by running a certain number of “warm-up” iterations before running the iterations used to time the code.

```{r message=FALSE}
library(microbenchmark)
set.seed(8)
tmp <- microbenchmark(a <- rnorm(1000), 
                      b <- mean(rnorm(1000)))
ggplot2::autoplot(tmp)
```

#### profvis
Once you’ve identified slower code, you’ll likely want to figure out which parts of the code are causing bottlenecks. The **profvis** function from the profvis package is very useful for this type of profiling.

```{r eval=FALSE}
library(profvis)
datafr <- dlnm::chicagoNMMAPS
threshold <- 27

profvis({
    highest_temp <- c()
    record_temp <- c()
    for(i in 1:nrow(datafr)){
        highest_temp <- max(highest_temp, datafr$temp[i])
        record_temp[i] <- datafr$temp[i] >= threshold & 
            datafr$temp[i] >= highest_temp
    }
    datafr <- cbind(datafr, record_temp)
})
```

**Documentation:**
https://rstudio.github.io/profvis/index.html

### Non-standard evaluation
Functions from packages like dplyr, tidyr, and ggplot2 are excellent for creating efficient and easy-to-read code that cleans and displays data. However, they allow shortcuts in calling columns in data frames that allow some room for ambiguity when you move from evaluating code interactively to writing functions for others to use. The non-standard evaluation used within these functions mean that, if you use them as you would in an interactive session, you’ll get a lot of “no visible bindings” warnings when you run CRAN checks on your package.


| Non-standard evaluation version | Standard evaluation version |
|---------------------------------|-----------------------------|
| aes(x = long, y = lat)          | aes_(x = ~ long, y = ~ lat) |

Summary:

* Functions that use non-standard evaluation can cause problems within functions written for a package.
* The NSE functions in tidyverse packages all have standard evaluation analogues that should be used when writing functions that will be used by others.

**Documentation:**
http://adv-r.had.co.nz/Computing-on-the-language.html


## Object-Oriented Programming
### OOP

The two older object oriented systems in R are called S3 and S4, and the modern system is called RC which stands for “reference classes.” Programmers who are already familiar with object oriented programming will feel at home using RC.

#### S3
Conveniently everything in R is an object. By “everything” I mean every single “thing” in R including numbers, functions, strings, data frames, lists, etc. If you want to know the class of an object in R you can simply use the class() function.

Class assignments can be made using the *structure()* function, or you can assign the class using *class()* and *<-*:

```{r}
special_num_1 <- structure(1, class = "special_number")
class(special_num_1) <- "special_number"
class(special_num_1)
```

This is completely legal R code, but if you want to have a better behaved S3 class you should create a constructor which returns an S3 object. The shape_S3() function below is a constructor that returns a shape_S3 object:

```{r}
shape_s3 <- function(side_lengths){
  structure(list(side_lengths = side_lengths), class = "shape_S3")
}

square_4 <- shape_s3(c(4, 4, 4, 4))
class(square_4)

triangle_3 <- shape_s3(c(3, 3, 3))
class(triangle_3)
```

We’ve now made two shape_S3 objects: square_4 and triangle_3, which are both instantiations of the shape_S3 class. **Imagine that you wanted to create a method that would return TRUE if a shape_S3 object was a square, FALSE if a shape_S3 object was not a square, and NA if the object provided as an argument to the method was not a shape_s3 object.** This can be achieved using R’s **generic** methods system. A generic method can return different values based depending on the class of its input. For example **mean() is a generic method** that can find the average of a vector of number or it can find the “average day” from a vector of dates. The following snippet demonstrates this behavior:

```{r}
mean(c(2, 3, 7))
mean(c(as.Date("2016-09-01"), as.Date("2016-09-03")))
```

Now let’s create a generic method for identifying shape_S3 objects that are squares. The creation of every generic method uses the UseMethod() function in the following way with only slight variations:

```{r}
is_square <- function(x) UseMethod("is_square")
```

Now we can add the actual function definition for detecting whether or not a shape is a square by specifying is_square.shape_S3. By putting a dot (.) and then the name of the class after is_squre, we can create a method that associates is_squre with the shape_S3 class:
```{r}
is_square.shape_S3 <- function(x){
  length(x$side_lengths) == 4 &&
    x$side_lengths[1] == x$side_lengths[2] &&
    x$side_lengths[2] == x$side_lengths[3] &&
    x$side_lengths[3] == x$side_lengths[4]
}

is_square(square_4)
is_square(triangle_3)
```

Seems to be working well! We also want is_square() to return NAwhen its argument is not a shape_S3. We can specifyis_square.default as a last resort if there is not method associated with the object passed to is_square().

```{r}
is_square.default <- function(x){
  NA
}

is_square("square")
is_square(c(1, 1, 1, 1))
```

Let’s try printing square_4:

```{r}
print(square_4)
```

Doesn’t that look ugly? Lucky for us print() is a generic method, so we can specify a print method for the shape_S3 class:

```{r}
print.shape_S3 <- function(x){
  if(length(x$side_lengths) == 3){
    paste("A triangle with side lengths of", x$side_lengths[1], 
          x$side_lengths[2], "and", x$side_lengths[3])
  } else if(length(x$side_lengths) == 4) {
    if(is_square(x)){
      paste("A square with four sides of length", x$side_lengths[1])
    } else {
      paste("A quadrilateral with side lengths of", x$side_lengths[1],
            x$side_lengths[2], x$side_lengths[3], "and", x$side_lengths[4])
    }
  } else {
    paste("A shape with", length(x$side_lengths), "slides.")
  }
}

print(square_4)
print(triangle_3)
print(shape_s3(c(10, 10, 20, 20, 15)))
print(shape_s3(c(2, 3, 4, 5)))
```

Since printing an object to the console is one of the most common things to do in R, nearly every class has an assocaited print method! To see all of the methods associated with a generic like print() use the methods() function:

```{r}
head(methods(print), 10)
```


One last note on S3 with regard to inheritance. In the previous section we discussed how a sub-class can inherit attributes and methods from a super-class. Since you can assign any class to an object in S3, you can specify a super class for an object the same way you would specify a class for an object:

```{r}
class(square_4)
class(square_4) <- c("shape_S3", "square")
class(square_4)
```

To check if an object is a sub-class of a specified class you can use the inherits() function:

```{r}
inherits(square_4, "square")
```


#### S4

The S4 system is slightly more restrictive than S3, but it’s similar in many ways. To create a new class in S4 you need to use the setClass() function. You need to specify two or three arguments for this function: Class which is the name of the class as a string,slots, which is a named list of attributes for the class with the class of those attributes specified, and optionally contains which includes the super-class of they class you’re specifying (if there is a super-class). Take look at the class definition for a bus_S4 and aparty_bus_S4 below:

```{r}
setClass("bus_S4",
         slots = list(n_seats = "numeric", 
                      top_speed = "numeric",
                      current_speed = "numeric",
                      brand = "character"))
setClass("party_bus_S4",
         slots = list(n_subwoofers = "numeric",
                      smoke_machine_on = "logical"),
         contains = "bus_S4")
```

Now that we’ve created the bus_S4 and the party_bus_S4 classes we can create bus objects using the new() function. The new() function’s arguments are the name of the class and values for each “slot” in our S4 object.

```{r}
my_bus <- new("bus_S4", n_seats = 20, top_speed = 80, 
              current_speed = 0, brand = "Volvo")
my_bus

my_party_bus <- new("party_bus_S4", n_seats = 10, top_speed = 100,
                    current_speed = 0, brand = "Mercedes-Benz", 
                    n_subwoofers = 2, smoke_machine_on = FALSE)
my_party_bus
```

You can use the @ operator to access the slots of an S4 object:

```{r}
my_bus@n_seats
my_party_bus@top_speed
```

This is essentially the same as using the $ operator with a list or an environment.

S4 classes use a generic method system that is similar to S3 classes. In order to implement a new generic method you need to use the setGeneric() function and the standardGeneric() function in the following way:

```{r eval=FALSE}
setGeneric("new_generic", function(x){
  standardGeneric("new_generic")
})
```

Let’s create a generic function called is_bus_moving() to see if a bus_S4 object is in motion:

```{r}
setGeneric("is_bus_moving", function(x){
  standardGeneric("is_bus_moving")
})
```

Now we need to actually define the function which we can to with setMethod(). The setMethod() functions takes as arguments the name of the method as a string, the method signature which specifies the class of each argument for the method, and then the function definition of the method:

```{r}
setMethod("is_bus_moving",
          c(x = "bus_S4"),
          function(x){
            x@current_speed > 0
          })

is_bus_moving(my_bus)
my_bus@current_speed <- 1
is_bus_moving(my_bus)
```

In addition to creating your own generic methods, you can also create a method for your new class from an existing generic. First use the setGeneric() function with the name of the existing method you want to use with your class, and then use the setMethod() function like in the previous example. Let’s make a print() method for the bus_S4 class:

```{r}
setGeneric("print")

setMethod("print",
          c(x = "bus_S4"),
          function(x){
            paste("This", x@brand, "bus is traveling at a speed of", x@current_speed)
          })

print(my_bus)
print(my_party_bus)
```


#### Reference Classes (RC)

With reference classes we leave the world of R’s old object oriented systems and enter the philosophies of other prominent object oriented programming languages. We can use the setRefClass() function to define a class’ fields, methods, and super-classes. Let’s make a reference class that represents a student:

```{r}
Student <- setRefClass("Student",
                      fields = list(name = "character",
                                    grad_year = "numeric",
                                    credits = "numeric",
                                    id = "character",
                                    courses = "list"),
                      methods = list(
                        hello = function(){
                          paste("Hi! My name is", name)
                        },
                        add_credits = function(n){
                          credits <<- credits + n
                        },
                        get_email = function(){
                          paste0(id, "@jhu.edu")
                        }
                      ))
```

To recap: we’ve created a class definition called Student which defines the student class. This class has five fields and three methods. To create a Student object use the new() method:

```{r}
brooke <- Student$new(name = "Brooke", grad_year = 2019, credits = 40,
                    id = "ba123", courses = list("Ecology", "Calculus III"))
roger <- Student$new(name = "Roger", grad_year = 2020, credits = 10,
                    id = "rp456", courses = list("Puppetry", "Elementary Algebra"))
```

You can access the fields and methods of each object using the $ operator:

```{r}
brooke$credits
roger$hello()
roger$get_email()
```

Methods can change the state of an object, for instance in the case of the add_credits() function:

```{r}
brooke$credits
brooke$add_credits(4)
brooke$credits
```

Notice that the add_credits() method uses the complex assignment operator (<<-). You need to use this operator if you want to modify one of the fields of an object with a method. You’ll learn more about this operator in the Expressions & Environments section.

Reference classes can inherit from other classes by specifying the contains argument when they’re defined. Let’s create a sub-class of Student called Grad_Student which includes a few extra features:

```{r}
Grad_Student <- setRefClass("Grad_Student",
                            contains = "Student",
                            fields = list(thesis_topic = "character"),
                            methods = list(
                              defend = function(){
                                paste0(thesis_topic, ". QED.")
                              }
                            ))

jeff <- Grad_Student$new(name = "Jeff", grad_year = 2021, credits = 8,
                    id = "jl55", courses = list("Fitbit Repair", 
                                                "Advanced Base Graphics"),
                    thesis_topic = "Batch Effects")

jeff$defend()
```


#### Summary:
* R has three object oriented systems: S3, S4, and Reference Classes.
* Reference Classes are the most similar to classes and objects in other programming languages.
* Classes are blueprints for an object.
* Objects are individual instances of a class.
* Methods are functions that are associated with a particular class.
* Constructors are methods that create objects.
* Everything in R is an object.
* S3 is a liberal object oriented system that allows you to assign a class to any object.
* S4 is a more strict object oriented system that build upon ideas in S3.
* Reference Classes are a modern object oriented system that is similar to Java, C++, Python, or Ruby.


### Gaining Your 'tidyverse' Citizenship

Many of the tools that we discuss in this book revolve around the so-called “tidyverse” set of tools. These tools, largely developed by Hadley Wickham but also including a diverse community of developers, have a set of principles that are adhered to when they are being developed. Hadley Wicham laid out these principles in his [Tidy Tools Manifesto](https://cran.r-project.org/web/packages/tidyverse/vignettes/manifesto.html), a vignette within the tidyverse package.