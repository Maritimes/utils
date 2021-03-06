% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert2poly.R
\name{convert2poly}
\alias{convert2poly}
\title{convert2poly}
\usage{
convert2poly(
  input = NULL,
  header = TRUE,
  out = "sf",
  lat.field = "X",
  lon.field = "Y",
  PID = "PID",
  SID = "SID",
  POS = "POS",
  shp.path = NULL
)
}
\arguments{
\item{input}{a PBSMapping PolySet to be converted (csv or df).}

\item{header}{indicates whether or not the input data has an initial row
describing the data.}

\item{out}{default is \code{'sf'}.  This indicates whether an \code{sf} object, 
\code{'sp'} (SpatialPolygonsDataFrame) or \code{'shp'} (shapefile) should be created.}

\item{lat.field}{the default is \code{"X"}. the name of the field holding latitude values
(in decimal degrees)}

\item{lon.field}{the default is \code{"Y"}.  the name of the field holding longitude
values (in decimal degrees)}

\item{PID}{the default is \code{"PID"}.  the name of the field holding primary 
identifiers for polygons}

\item{SID}{the default is \code{"SID"}.  the name of the field holding secondary 
identifiers for polygons}

\item{POS}{the default is \code{"POS"}.  the name of the field holding the 
order in which the provided coordinates should be joined}

\item{shp.path}{if \code{out ='shp'}, this is the path to where the shapefile 
should be saved.  sf and sp objects are just created in the environment}
}
\value{
an sf object, a SpatialPolygonsDataFrame,or a shapefile
}
\description{
This function will accept a PBSMapping style csv, a df or a 
spatialpolygondataframe and turn it into an  sf object, an sp object or a shapefile.
}
\note{
if no  PID or POS is provided, it is assumed that the provided positions
are for a single polygon and the position are in the correct order.
}
\seealso{
Other general_use: 
\code{\link{clip_by_poly_generic}()},
\code{\link{combine_lists}()},
\code{\link{df2sf}()},
\code{\link{df_qc_spatial}()},
\code{\link{df_to_shp}()},
\code{\link{df_to_sp}()},
\code{\link{drop_cols}()},
\code{\link{pbs2sp_poly}()},
\code{\link{prepare_shape_fields}()},
\code{\link{updateCheck}()}
}
\author{
Mike McMahon, \email{Mike.McMahon@dfo-mpo.gc.ca}
}
\concept{general_use}
