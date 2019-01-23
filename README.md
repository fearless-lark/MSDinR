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
editor_options: 
  chunk_output_type: inline
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


## Final project submission link
https://www.coursera.org/learn/advanced-r/peer/98rUI/functional-and-object-oriented-programming/review/MGd_ERsLEemW9AqIrtIhIA



# Building R Packages
## Getting Started with R Packages
### R Packages
#### Basic Structure of an R Package

An R package begins life as a directory on your computer. This directory has a specific layout with specific files and sub-directories. The two required sub-directories are

R, which contains all of your R code files
man, which contains your documentation files.
At the top level of your package directory you will have a DESCRIPTION file and a NAMESPACE file. This represents the minimal requirements for an R package. Other files and sub-directories can be added and will discuss how and why in the sections below.

ё
#### DESCRIPTION File
The DESCRIPTION file is an essential part of an R package because it contains key metadata for the package that is used by repositories like CRAN and by R itself. In particular, this file contains the package name, the version number, the author and maintainer contact information, the license information, as well as any dependencies on other packages.

#### NAMESPACE File
The NAMESPACE file specifies the interface to the package that is presented to the user. This is done via a series of export() statements, which indicate which functions in the package are exported to the user. Functions that are not exported cannot be called directly by the user (although see below). In addition to exports, the NAMESPACE file also specifies what functions or packages are imported by the package. If your package depends on functions from another package, you must import them via the NAMESPACE file.

#### Namespace Function Notation
```{r eval=FALSE}
"<package name>::<exported function name>"
```


It is possible to call functions that are not exported by package by using the namespace notation. Use of the ::: operator is not allowed for packages that reside on CRAN.

#### Loading and Attaching a Package Namespace
When dealing with R packages, it’s useful to understand the distinction between loading a package namespace and attaching it. When package A imports the namespace of package B, package A loads the namespace of package B in order to gain access to the exported functions of package B. However, when the namespace of package B is loaded, it is only available to package A; it is not placed on the search list and is not visible to the user or to other packages.

Attaching a package namespace places that namespace on the search list, making it visible to the user and to other packages. Sometimes this is needed because certain functions need to be made visible to the user and not just to a given package.

#### The R Sub-directory
The R sub-directory contains all of your R code, either in a single file, or in multiple files. For larger packages it’s usually best to split code up into multiple files that logically group functions together. The names of the R code files do not matter, but generally it’s not a good idea to have spaces in the file names.


#### The man Sub-directory
The man sub-directory contains the documentation files for all of the exported objects of a package. With older versions of R one had to write the documentation of R objects directly into the man directory using a LaTeX-style notation. However, with the development of the roxygen2 package, we no longer need to do that and can write the documentation directly into the R code files. Therefore, you will likely have little interaction with the man directory as **all of the files in there will be auto-generated by the roxygen2 package.**


### The devtools package

Hands down, the best resource for mastering the devtools package is the book R Packages by Hadley Wickham. The full book is available online for free at http://r-pkgs.had.co.nz

Here are some of the key functions included in devtools and what they do, roughly in the order you are likely to use them as you develop an R package:

| Function          | Use                                                                                                                                                                                                                                                               |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| load_all          | Load the code for all functions in the package                                                                                                                                                                                                                    |
| document          | Create \man documentation files and the “NAMESPACE” file from roxygen2 code                                                                                                                                                                                       |
| use_data          | Save an object in your R session as a dataset in the package                                                                                                                                                                                                      |
| use_vignette      | Set up the package to include a vignette                                                                                                                                                                                                                          |
| use_readme_rmd    | Set up the package to include a README file in Rmarkdown format                                                                                                                                                                                                   |
| use_build_ignore  | Specify files that should be ignored when building the R package (for example, if you have a folder where you’re drafting a journal article about the package, you can include all related files in a folder that you set to be ignored during the package build) |
| check             | Check the full R package for any ERRORs, WARNINGs, or NOTEs                                                                                                                                                                                                       |
| build_win         | Build a version of the package for Windows and send it to be checked on a Windows machine. You’ll receive an email with a link to the results.                                                                                                                    |
| use_travis        | Set the package up to facilitate using Travis CI with the package                                                                                                                                                                                                 |
| use_cran_comments | Create a file where you can add comments to include with your CRAN submission.                                                                                                                                                                                    |
| submit_cran       | Submit the package to CRAN                                                                                                                                                                                                                                        |
| use_news_md       | Add a file to the package to give news on changes in new versions                                                                                                                                                                                                 |



#### Creating a Package
The earliest infrastructure function you will use from the devtools package is create. This function inputs the filepath for the directory where you would like to create the package and creates the initial package structure (as a note, this directory should not yet exist). You will then add the elements (code, data, etc.) for the package within this structure. As an alternative to create, you can also initialize an R package in RStudio by selecting “File” -> “New Project” -> “New Direction” -> “R Package”.


## Documentation and Testing
### Documentation
#### Vignette's and README Files
You will likely want to create a document that walks users through the basics of how to use your package. You can do this through two formats:

* Vignette: This document is bundled with your R package, so it becomes locally available to a user once they install your package from CRAN. They will also have it available if they install the package from GitHub, as long as they use the build_vignettes = TRUE when running install_github.
* README file: If you have your package on GitHub, this document will show up on the main page of the repository.

A package likely only needs a README file if you are posting the package to GitHub. For any GitHub repository, if there is a README.md file in the top directory of the repository, it will be rendered on the main GitHub repository page below the listed repository content. 

If the README file does not need to include R code, you can write it directly as an .md file, using Markdown syntax, which is explained in more detail in the next section. If you want to include R code, you should start with a README.Rmd file, which you can then render to Markdown using knitr. You can use the devtools package to add either a README.md or README.Rmd file to a package directory, using use_readme_md or use_readme_rmd, respectively. These functions will add the appropriate file to the top level of the package directory and will also add the file name to “.Rbuildignore”, since having one of these files in the top level of the package directory could otherwise cause some problems when building the package.

The README file is a useful way to give GitHub users information about your package, but it will not be included in builds of the package or be available through CRAN for packages that are posted there. Instead, if you want to create tutorials or overview documents that are included in a package build, you should do that by adding one or more package vignettes. Vignettes are stored in a vignettes subdirectory within the package directory.

To add a vignette file, saved within this subdirectory (which will be created if you do not already have it), use the use_vignette function from devtools. This function takes as arguments the file name of the vignette you’d like to create and the package for which you’d like to create it (the default is the package in the current working directory). For example, if you are currently working in your package’s top-level directory and you would like to add a vignette called “model_details”, you can do that with the code:

```{r eval=FALSE}
use_vignette("model_details")
```

You can have more than one vignette per package, which can be useful if you want to include one vignette that gives a more general overview of the package as well as a few vignettes that go into greater detail about particular aspects or applications.

Once you create a vignette with use_vignette, be sure to update the Vignette Index Entry in the vignette’s YAML (the code at the top of an R Markdown document). Replace “Vignette Title” there with the actual title you use for the vignette.



#### Common knitr chunk options

You can set “global” options at the beginning of the document. This will create new defaults for all of the chunks in the document. For example, if you want echo, warning, and message to be FALSE by default in all code chunks, you can run:

```{r  global_options, eval=FALSE}
knitr::opts_chunk$set(echo = FALSE, message = FALSE,
  warning = FALSE)
```

[Table of Common knitr Options](https://bookdown.org/rdpeng/RProgDA/documentation.html#common-knitr-chunk-options)

[R Markdown Cheatsheet](https://www.rstudio.com/wp-content/uploads/2015/02/rmarkdown-cheatsheet.pdf)

#### Help Files and roxygen2

In addition to writing tutorials that give an overview of your whole package, you should also write specific documentation showing users how to use and interpret any functions you expect users to directly call.

These help files will ultimately go in a folder called /man of your package, in an R documentation format (.Rd file extensions) that is fairly similar to LaTex. You used to have to write all of these files as separate files. However, the roxygen2 package lets you put all of the help information directly in the code where you define each function.

With roxygen2, you add the help file information directly above the code where you define each functions, in the R scripts saved in the R subdirectory of the package directory. You start each line of the roxygen2 documentation with #' (the second character is an apostrophe, not a backtick). The first line of the documentation should give a short title for the function, and the next block of documentation should be a longer description. After that, you will use tags that start with @ to define each element you’re including. You should leave an empty line between each section of documentation, and you can use indentation for second and later lines of elements to make the code easier to read.

Here is a basic example of how this roxygen2 documentation would look for a simple “Hello world” function:

```{r eval=F}
#' Print "Hello world" 
#'
#' This is a simple function that, by default, prints "Hello world". You can 
#' customize the text to print (using the \code{to_print} argument) and add
#' an exclamation point (\code{excited = TRUE}).
#'
#' @param to_print A character string giving the text the function will print
#' @param excited Logical value specifying whether to include an exclamation
#'    point after the text
#' 
#' @return This function returns a phrase to print, with or without an 
#'    exclamation point added. As a side effect, this function also prints out
#'    the phrase. 
#'
#' @examples
#' hello_world()
#' hello_world(excited = TRUE)
#' hello_world(to_print = "Hi world")
#'
#' @export
hello_world <- function(to_print = "Hello world", excited = FALSE){
    if(excited) to_print <- paste0(to_print, "!")
    print(to_print)
}
```


#### Common roxygen2 Tags

Common roxygen2 tags to use in creating this documentation: 
[Table of common roxygen2 tags](https://bookdown.org/rdpeng/RProgDA/documentation.html#common-roxygen2-tags)

Here are a few things to keep in mind when writing help files using roxygen2:

The tags @example and @examples do different things. You should always use the @examples (plural) tag for example code, or you will get errors when you build the documentation.

The @inheritParams function can save you a lot of time, because if you are using the same parameters in multiple functions in your package, you can write and edit those parameter descriptions just in one place. However, keep in mind that you must point @inheritParams to the function where you originally define the parameters using @param, not another function where you use the parameters but define them using an @inheritParams pointer.

If you want users to be able to directly use the function, you must include @export in your roxygen2 documentation. If you have written a function but then find it isn’t being found when you try to compile a README file or vignette, a common culprit is that you have forgotten to export the function.

You can include formatting (lists, etc.) and equations in the roxygen2 documentation. Here are some of the common formatting tags you might want to use: [Table of common roxygen2 formatting tags](https://bookdown.org/rdpeng/RProgDA/documentation.html#common-roxygen2-formatting-tags).

Some tips on using the R documentation format:

* Usually, you’ll want you use the \link tag only in combination with the \code tag, since you’re linking to another R function. Make sure you use these with \code wrapping \link, not the other way around (\code{\link{other_function}}), or you’ll get an error.
* Some of the equation formatting, including superscripts and subscripts, won’t parse in Markdown-based documentation (but will for pdf-based documentation). With the \eqn and deqn tags, you can include two versions of an equation, one with full formatting, which will be fully compiled by pdf-based documentation, and one with a reduced form that looks better in Markdown-based documentation (for example, \deqn{ \frac{X^2}{Y} }{ X2 / Y }).
* For any examples in help files that take a while to run, you’ll want to wrap the example code in the \dontrun tag.
* The tags \url and \href both include a web link. The difference between the two is that \url will print out the web address in the help documentation, href allows you to use text other than the web address for the anchor text of the link. For example: "For more information, see \url{www.google.com}."; "For more information, \href{www.google.com}{Google it}.".


In addition to document functions, you should also document any data that comes with your package. To do that, create a file in the /R folder of the package called “data.R” to use to documentation all of the package’s datasets. You can use roxygen2 to document each dataset, and end each with the name of the dataset in quotation marks. There are more details on documenting package data using roxygen2 in the next section.






### Data Within a Package
#### Data for Demos
##### Data Objects
Including data in your package is easy thanks to the devtools package. To include datasets in a package, first create the objects that you would like to include in your package inside of the global environment. You can include any R object in a package, not just data frames. Then make sure you’re in your package directory and use the use_data() function, listing each object that you want to include in your package. The names of the objects that you pass as arguments to use_data() will be the names of the objects when a user loads the package, so make sure you like the variable names that you’re using.

You should then document each data object that you’re including in the package. This way package users can use common R help syntax like ?dataset to find out more information about the included data set. You should create one R file called data.R in the R/ directory of your package. You can write the data documentation in the data.R file. Let’s take a look at some documentation examples from the minimap package. First we’ll look at the documentation for a data frame called maple:

```{r eval=FALSE}
#' Production and farm value of maple products in Canada
#'
#' @source Statistics Canada. Table 001-0008 - Production and farm value of
#'  maple products, annual. \url{http://www5.statcan.gc.ca/cansim/}
#' @format A data frame with columns:
#' \describe{
#'  \item{Year}{A value between 1924 and 2015.}
#'  \item{Syrup}{Maple products expressed as syrup, total in thousands of gallons.}
#'  \item{CAD}{Gross value of maple products in thousands of Canadian dollars.}
#'  \item{Region}{Postal code abbreviation for territory or province.}
#' }
#' @examples
#' \dontrun{
#'  maple
#' }
"maple"
```

Data frames that you include in your package should follow the general schema above where the documentation page has the following attributes:

An informative title describing the object.

A @source tag describing where the data was found.

A @format tag which describes the data in each column of the data frame.

And then finally a string with the name of the object.

The minimap package also includes a few vectors. Let’s look at the documentation for mexico_abb:

```{r eval=FALSE}
#' Postal Abbreviations for Mexico
#'
#' @examples
#' \dontrun{
#'  mexico_abb
#' }
"mexico_abb"
```

You should always include a title for a description of a vector or any other object. If you need to elaborate on the details of a vector you can include a description in the documentation or a @source tag. Just like with data frames the documentation for a vector should end with a string containing the name of the object.

##### Raw Data
A common task for R packages is to take raw data from files and to import them into R objects so that they can be analyzed. You might want to include some sample raw data files so you can show different methods and options for importing the data. To include raw data files in your package you should create a directory under inst/extdata in your R package. If you stored a data file in this directory called response.json in inst/extdata and your package is named mypackage then a user could access the path to this file with system.file("extdata", "response.json", package = "mypackage"). Include that line of code in the documentation to your package so that your users know how to access the raw data file.

##### Internal Data
Functions in your package may need to have access to data that you don’t want your users to be able to access. For example the swirl package contains translations for menu items into languages other than English, however that data has nothing to do with the purpose of the swirl package and so it’s hidden from the user. To add internal data to your package you can use the use_data() function from devtools, however you must specify the internal = TRUE argument. All of the objects you pass to use_data(..., internal = TRUE) can be referenced by the same name within your R package. All of these objects will be saved to one file called R/sysdata.rda.

### Software Testing Framework for R Packages
#### The testthat Package
The testthat package is designed to make it easy to setup a battery of tests for your R package. A nice introduction to the package can bef ound in Hadley Wickham’s [article](https://journal.r-project.org/archive/2011-1/RJournal_2011-1_Wickham.pdf) in the R Journal. Essentially, the package contains a suite of functions for testing function/expression output with the expected output. The simplest use of the package is for testing a simple expression:

```{r eval}
library(testthat)
expect_that(sqrt(3) * sqrt(3), equals(3))
```

Note that the equals() function allows for some numerical fuzz, which is why this expression actually passes the test. When a test fails, expect_that() throws an error and does not return something.

```{r eval=FALSE}
## Use a strict test of equality (this test fails)
expect_that(sqrt(3) * sqrt(3), is_identical_to(3))

# Error: sqrt(3) * sqrt(3) not identical to 3.
# Objects equal but not identical
```

The expect_that() function can be used to wrap many different kinds of test, beyond just numerical output. The table below provides a brief summary of the types of comparisons that can be made.

| Expectation        | Description                                          |
|--------------------|------------------------------------------------------|
| equals()           | check for equality with numerical fuzz               |
| is_identical_to()  | strict equality via identical()                      |
| is_equivalent_to() | like equals() but ignores object attributes          |
| is_a()             | checks the class of an object (using inherits())     |
| matches()          | checks that a string matches a regular expression    |
| prints_text()      | checks that an expression prints to the console      |
| shows_message()    | checks for a message being generated                 |
| gives_warning()    | checks that an expression gives a warning            |
| throws_error()     | checks that an expression (properly) throws an error |
| is_true()          | checks that an expression is TRUE                    |

A collection of calls to expect_that() can be put together with the test_that() function, as in

```{r}
test_that("model fitting", {
        data(airquality)
        fit <- lm(Ozone ~ Wind, data = airquality)
        expect_that(fit, is_a("lm"))
        expect_that(1 + 1, equals(2))
})
```

Typically, you would put your tests in an R file. If you have multiple sets of tests that test different domains of a package, you might put those tests in different files. Individual files can have their tests run with the test_file() function. A collection of tests files can be placed in a directory and tested all together with the test_dir() function.

In the context of an R package, it makes sense to put the test files in the tests directory. This way, when running R CMD check (see the next section) all of the tests will be run as part of process of checking the entire package. If any of your tests fail, then the entire package checking process will fail and will prevent you from distributing buggy code. If you want users to be able to easily see the tests from an installed package, you can place the tests in the inst/tests directory and have a separate file in the tests directory run all of the tests.

### Passing CRAN checks
Before submitting a package to CRAN, you must pass a battery of tests that are run by the R itself via the R CMD check program. In RStudio, if you are in an R Package “Project” you can run R CMD check by clicking the Check button in the build tab. This will run a series of tests that check the metadata in your package, the NAMESPACE file, the code, the documentation, run any tests, build any vignettes, and many others.

## Licensing, Version Control, and Software Design
### Open Source Licensing
You can specify how your R package is licensed in the package DESCRIPTION file under the License: section. How you license your R package is important because it provides a set of constraints for how other R developers use your code. If you’re writing an R package to be used internally in your company then your company may choose to not share the package. In this case licensing your R package is less important since the package belongs to your company. In your package DESCRIPTION you can specify License: file LICENSE, and then create a text file called LICENSE which explains that your company reserves all rights to the package.

However if you (or your company) would like to publicly share your R package you should consider open source licensing. The philosophy of open source revolves around three principles:

* The source code of the software can be inspected.
* The source code of the software can be modified.
* Modified versions of the software can be redistributed.

Nearly all open source licenses provide the protections above. Let’s discuss three of the most popular open source licenses among R packages.


#### The General Public License
Known as the GPL, the GNU GPL, and GPL-3, the General Public License was originally written by Richard Stallman. The GPL is known as a copyleft license, meaning that any software that is bundled with or originates from software licensed under the GPL must also be released under the GPL. The exacting meaning of “bundle” will depend a bit on the circumstances. For example, software distributed with an operating system can be licensed under different licenses even if the operating system itself is licensed under the GPL. You can use the GPL-3 as the license for your R package by specifying License: GPL-3 in the DESCRIPTION file.

It is worth noting that R itself is licensed under version 2 of the GPL, or GPL-2, which is an earlier version of this license.



#### The MIT License
The MIT license is a more permissive license compared to the GPL. MIT licensed software can be modified or incorporated into software that is not open source. The MIT license protects the copyright holder from legal liability that might be incurred from using the software. When using the MIT license in a R package you should specify License: MIT + file LICENSE in the DESCRIPTION file. You should then add a file called LICENSE to your package which uses the following template exactly:

```{r eval=FALSE}
YEAR: [The current year]
COPYRIGHT HOLDER: [Your name or your organization's name]
```



#### The CC0 License
The [Creative Commons](https://creativecommons.org/) licenses are usually used for artistic and creative works, however the CC0 license is also appropriate for software. The CC0 license dedicates your R package to the public domain, which means that you give up all copyright claims to your R package. The CC0 license allows your software to join other great works like Pride and Prejudice, The Adventures of Huckleberry Finn, and The Scarlet Letter in the public domain. You can use the CC0 license for your R package by specifying License: CC0 in the DESCRIPTION file.


### Software Design and Philosophy
#### Naming Things
Be sure that you’re not assigning names that already exist and are common in R. For example mean, summary, and rt are already names of functions in R, so try to avoid overwriting them. You can check if a name is taken using the apropos() function:

## Continuous Integration and Cross Platform Development
### Continuous Integration
#### Web Services for Continuous Integration

We’ll discuss two services for continuous integration: the first is [Travis](https://travis-ci.org/) which will test your package on Linux, and then there’s [AppVeyor](https://www.appveyor.com/) which will test your package on Windows. Both of these services are free for R packages that are built in public GitHub repositories. These continuous integration services will run every time you push a new set of commits for your package repository. Both services integrate nicely with GitHub so you can see in GitHub’s pull request pages whether or not your package is building correctly.

#### Using Travis
To start using Travis go to https://travis-ci.org and sign in with your GitHub account. Clicking on your name in the upper right hand corner of the site will bring of a list of your public GitHub repositories with a switch next to each repo. If you turn the switch on then the next time you push to that repository Travis will look for a .travis.yml file in the root of the repository, and it will run tests on your package accordingly.

Open up your R console and navigate to your R package repository. Now load the devtools package with library(devtools) and enter use_travis() into your R console. This command will set up a basic .travis.yml for your R package. You can now add, commit, and push your changes to GitHub, which will trigger the first build of your package on Travis. Go back to https://travis-ci.org to watch your package be built and tested at the same time! You may want to make some changes to your .travis.yml file, and you can see all of the options available in [this guide](https://docs.travis-ci.com/user/languages/r).

Once your package has been built for the first time you’ll be able to obtain a badge, which is just a small image generated by Travis which indicates whether you package is building properly and passing all of your tests. You should display this badge in the README.md file of your package’s GitHub repository so that you and others can monitor the build status of your package.


#### Using AppVeyor

You can start using AppVeyor by going to https://www.appveyor.com/ and signing in with your GitHub account. After signing in click on “Projects” in the top navigation bar. If you have any GitHub repositories that use AppVeyor you’ll be able to see them here. To add a new project click “New Project” and find the GitHub repo that corresponds to the R package you’d like to test on Windows. Click “Add” for AppVeyor to start tracking this repo.

Open up your R console and navigate to your R package repository. Now load the devtools package with library(devtools) and enter use_appveyor() into your R console. This command will set up a default appveyor.yml for your R package. You can now add, commit, and push your changes to GitHub, which will trigger the first build of your package on AppVeyor. Go back to https://www.appveyor.com/ to see the result of the build. You may want to make some changes to your appveyor.yml file, and you can see all of the options available in the [r-appveyor](https://github.com/krlmlr/r-appveyor/blob/master/README.md) guide which is maintained by Kirill Müller. Like Travis, AppVeyor also generates badges that you should add to the README.md file of your package’s GitHub repository.

### Cross Platform Development
#### Handling Paths
The correct programmatic way to construct the path above is to use the file.path() function. So to get the file above I would do the following:
```{r}
file.path("~", "Desktop", "data.txt")
```

System name:
```{r}
Sys.info()['sysname']
```

In general it’s not guaranteed on any system that a particular file or folder you’ve looking for will exist - however if the user of your package has installed your package you can be sure that any files within your package exist on their machine. You can find the path to files included in your package using the system.file() function. Any files or folders in the inst/ directory of your package will be copied one level up once your package is installed. If your package is called ggplyr2 and there’s file in your package under inst/data/first.txt you can get the path to that file with system.file("data", "first.txt", package = "ggplyr2"). Packaging files with your package is the best way to ensure that users have access to them when they’re using your package.


The path.expand() function is usually used to find the absolute path name of a user’s home directory when the tilde (~) is inlcuded in the path. The tilde is a shortcut for the path to the current user’s home directory. Let’s take a look at path.expand() in action:
```{r}
path.expand("~")
path.expand(file.path("~", "Desktop"))
```


The normalizePath() function is built on top of path.expand(), so it includes path.expand()’s features but it also creates full paths for other shortcuts like "." which signifies the current working directory and ".." which signifies the directory above the current working directory. Let’s take a look at some examples:
```{r}
normalizePath(file.path("~", "R"))
normalizePath(".")
normalizePath("..")
```

To extract parts of a path you can use the basename() function to get the name of the file or the deepest directory in the path and you can use dirname() to get the part of the path that does not include either the file or the deepest directory. Let’s take a look at some examples:
```{r}
data_file <- normalizePath(file.path("~", "data.txt"))
data_file
dirname(data_file)
dirname(dirname(data_file))
basename(data_file)
```

#### Saving Files & rappdirs
In general you should strive to get the user’s consent before you create or save files on their computer. With some functions consent is implicit, for example it’s clear somebody using write.csv() consents to producing a csv file at a specified path. When it’s not absolutely clear that the user will be creating a file or folder when they use your functions you should ask them specifically. Take a look at the code below for a skeleton of a function that asks for a user’s consent:

```{r eval=FALSE}
#' A function for doing something
#'
#' This function takes some action. It also attempts to create a file on your
#' desktop called \code{data.txt}. If \code{data.txt} cannot be created a
#' warning is raised.
#' 
#' @param force If set to \code{TRUE}, \code{data.txt} will be created on the
#' user's Desktop if their Desktop exists. If this function is used in an
#' interactive session the user will be asked whether or not \code{data.txt}
#' should be created. The default value is \code{FALSE}.
#'
#' @export
some_function <- function(force = FALSE){
  
  #
  # ... some code that does something useful ...
  #
  
  if(!dir.exists(file.path("~", "Desktop"))){
    warning("No Desktop found.")
  } else {
    if(!force && interactive()){
      result <- select.list(c("Yes", "No"), 
                  title = "May this program create data.txt on your desktop?")
      if(result == "Yes"){
        file.create(file.path("~", "Desktop", "data.txt"))
      }
    } else if(force){
      file.create(file.path("~", "Desktop", "data.txt"))
    } else {
      warning("data.txt was not created on the Desktop.")
    }
  }
}
```

The some_function() function above is a contrived example of how to ask for permission from the user to create a file on their hard drive. Notice that the description of the function clearly states that the function attempts to create the data.txt file. This function has a force argument which will create the data.txt file without asking the user first. By setting force = FALSE as the default, the user must set force = TRUE, which is one method to get consent from the user. The function above uses the interactive() function in order to determine whether the user is using this function in an R console or if this function is being run in a non-interactive session. If the user is in an interactive R session then using select.list() is a decent method to ask the user a question. You should strive to use select.list() and interactive() together in order to prevent an R session from waiting for input from a user that doesn’t exist.

#### rappdirs
Even the contrived example above implicitly raises a good question: where should your package save files? The most obvious answer is to allow the user to provide an argument for the path where a file should be saved. This is a good idea as long as your package won’t need to depend on the location of that file in the future, for example if your package is creating an output data file. But what if you need persistent and consistent access to a file? You might be tempted to use path.package() in order to find the directory that your package is installed in so you can store files there. This isn’t a good idea because file access permissions often do not allow users to modify files where R packages are stored.

In order to find a location where you can read and write files that will persist on a user’s computer you should use the rappdirs package. This package contains functions that will return paths to directories where you package can store files for future use. The user_data_dir() function will provide a user-specific path for your package, while the site_data_dir() function will return a directory path that is shared by all users. Let’s take a look at rappdirs in action:

```{r}
library(rappdirs)
site_data_dir(appname = "ggplyr2", os = "win")
user_data_dir(appname = "ggplyr2", os = "win")
```

If you don’t supply the os argument then the function will determine the operating system automatically. One feature about user_data_dir() you should note is the roaming = TRUE argument. Many Windows networks are configured so that any authorized user can log in to any computer on the network and have access to their desktop, settings, and files. Setting roaming = TRUE returns a special path so that R will have access to your packages files everywhere, but this requires the directory to be synced often. Make sure to only use roaming = TRUE if the files your package will storing with rappdirs are going to be small. For more information about rappdirs see https://github.com/hadley/rappdirs.



#### Options and Starting R

Several R Packages allow users to set global options that effect the behavior of the package using the options() function. The options() function returns a list, and named values in this list can be set using the following syntax: options(key = value). It’s a common feature for packages to allow a user to set options which may specify package defaults, or change the behavior of the package in some way. You should thoroughly document how your package is effected by which options are set.

When an R session begins a series of files are searched for and run if found as detailed in help("Startup"). One of those files is .Rprofile. The .Rprofile file is just a regular R file which is usually located in a user’s home directory (which you can find with normalizePath("~")). A user’s .Rprofile is run every time they start an R session, so it’s a good file for setting options that a user wants to be set when using R. If you want a user to be able to set an option that is related to your package that is unlikely to change (like a username or a key), then you should consider instructing them to create or make changes to their .Rprofile.




#### Package Installation

Your package documentation should prominently feature installation instructions. Many R packages that are distributed through GitHub recommend installing the devtools package, and then using devtools::install_github() to install the package. The devtools package is wonderful for developing R packages, but it has many dependencies whhich can make it difficult for users to install. I recommend instructing folks to use the ghit package by Thomas Leeper and the ghit::install_github() function as a reliable alternative to devtools.

In cases where users might have a weak internet connection it’s often easier for a user to download the source of your package as a zip file and then to install it using install.packages(). Instead of asking users to discern the path of zip file they’ve downloaded you should ask them to enter *install.packages(file.choose(), repos = NULL, type = "source")** into the R console and then they can interactively select the file they just downloaded. If a user is denied permission to modify their local package directory, they still may be able to use a package if they specify a directory they have access to with the lib argument for install.packages().


#### Environmental Attributes

 The environmental variables .Platform and .Machine are lists which contain named elements that can tell your program about the underlying machine. For example .Platform$OS.type is a good method for checking whether your program is in a Windows environment since the only values it can return are "windows" and "unix":
```{r}
.Platform$OS.type
```

For more information about information contained in .Platform see the help file: help(".Platform").

The .Machine variable contains information specific to the computer architecture that your program is being run on. For example .Machine\$double.xmax and .Machine\$double.xmin are respectively the largest and smallest positive numbers that can be represented in R on your platform:

```{r}
.Machine$double.xmax
.Machine$double.xmax + 100 == .Machine$double.xmax
.Machine$double.xmin
```

You might also find .Machine\$double.eps useful, which is the smallest number on a machine such that 1 + .Machine\$double.eps != 1 evaluates to TRUE:

```{r}
1 + .Machine$double.eps != 1
1 + .Machine$double.xmin != 1
```


#### Summary
File and folder paths differ across platforms so R provides several functions to ensure that your program can construct paths correctly. The rappdirs package helps further by identifying locations where you can safely store files that your package can access. However before creating files anywhere on a user’s disk you should always ask the user’s permission. You should provide clear and easy instructions so people can easily install your package. The .Platform and .Machine variables can inform your program about hardware and software details.