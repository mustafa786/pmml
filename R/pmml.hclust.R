# PMML: Predictive Modelling Markup Language
#
# Part of the Rattle package for Data Mining
#
# Time-stamp: <2009-01-05 10:41:48 Graham Williams>
#
# Copyright (c) 2009 Togaware Pty Ltd
#
# This files is part of the Rattle suite for Data Mining in R.
#
# Rattle is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# Rattle is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Rattle. If not, see <http://www.gnu.org/licenses/>.

########################################################################

pmml.hclust <- function(model,
                        model.name="HClust_Model",
                        app.name="Rattle/PMML",
                        description="Hierarchical cluster model",
                        copyright=NULL,
                        transforms=NULL,
                        centers,
                        ...)
{
  require(XML, quietly=TRUE)
  
  if (! inherits(model, "hclust")) stop("Not a legitimate hclust object")

  # Collect the required information.

  field <- NULL
  field$name <-  colnames(centers)
  orig.fields <- field$name

  if (exists("pmml.transforms") && ! is.null(transforms))
    field$name <- unifyTransforms(field$name, transforms)

  number.of.fields <- length(field$name)

  field$class <- rep("numeric", number.of.fields) # All fields are numeric
  names(field$class) <- field$name

  number.of.clusters <- nrow(centers)
  cluster.names <- 1:number.of.clusters

  # PMML

  pmml <- pmmlRootNode("3.2")

  # PMML -> Header

  pmml <- append.XMLNode(pmml, pmmlHeader(description, copyright, app.name))

  # PMML -> DataDictionary

  pmml <- append.XMLNode(pmml, pmmlDataDictionary(field))

  # PMML -> ClusteringModel

  cl.model <- xmlNode("ClusteringModel",
                      attrs=c(modelName=model.name,
                        functionName="clustering", # Required
                        algorithmName="HClust",
                        modelClass="centerBased", # Required
                        numberOfClusters=number.of.clusters)) # Required

  # PMML -> ClusteringModel -> MiningSchema

  cl.model <- append.XMLNode(cl.model, pmmlMiningSchema(field))

  # PMML -> ClusteringModel -> LocalTransformations -> DerivedField -> NormContiuous

  if (exists("pmml.transforms") && ! is.null(transforms))
    cl.model <- append.XMLNode(cl.model, pmml.transforms(transforms))
  
  # PMML -> ClusteringModel -> ComparisonMeasure
  
  cl.model <- append.XMLNode(cl.model,
                             append.XMLNode(xmlNode("ComparisonMeasure",
                                                    attrs=c(kind="distance")),
                                            xmlNode("squaredEuclidean")))

  # PMML -> ClusteringField

  for (i in orig.fields)
  {
    cl.model <- append.xmlNode(cl.model,
                               xmlNode("ClusteringField",
                                       attrs=c(field=i)))
  }
  
  # PMML -> ClusteringModel -> Cluster -> Array
  
  clusters <- list()
  for (i in 1:number.of.clusters)
  {
    cl.model <- append.XMLNode(cl.model,
                               xmlNode("Cluster",
                                       attrs=c(name=cluster.names[i],
                                         size=model$size[i]),
                                       xmlNode("Array",
                                               attrs=c(n=number.of.fields,
                                                 type="real"),
                                               paste(centers[i,],
                                                     collapse=" "))))
  }
  pmml <- append.XMLNode(pmml, cl.model)

  return(pmml)
}