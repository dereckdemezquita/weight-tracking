
files <- list.files("./food-data/", full.names = TRUE)
names(files) <- fs::path_ext_remove(list.files("./food-data/"))

dataset <- lapply(files, function(file) {
	data <- data.table::fread(file, header = FALSE)
	colnames(data) <- c("variable", "metric")
	return(data)
})

dataset <- mapply(function(food, name) {
	food <- data.table::transpose(food, make.names = "variable")
	food$name <- name
	
	return(food)
}, dataset, names(dataset), SIMPLIFY = FALSE)

col_names <- lapply(dataset, "colnames")
sapply(col_names, function(x) {
	setdiff(col_names[[1]], x)
})

dataset <- data.table::rbindlist(dataset, fill = TRUE)

units <- lapply(dataset, function(col) {
	unit <- unique(gsub("[\\.|0-9]+", "", col[!is.na(col)]))
	unit <- unit[unit != ""]
	if(length(unit) == 1) {
		return(unit)
	} else {
		return(NA)
	}
})

units <- mapply(function(unit, colname) {
	if(!is.na(unit)) {
		stringr::str_interp('${colname} (${unit})')
	} else {
		return(colname)
	}
}, units, names(units), SIMPLIFY = FALSE)

colnames(dataset) <- unname(unlist(units))


dataset[, colnames(dataset) := lapply(.SD, function(col) {
	unit <- unique(gsub("[\\.|0-9]+", "", col[!is.na(col)]))
	unit <- unit[unit != ""]
	if(length(unit) == 1) {
		return(gsub("[mg|g|mcg]+", "", col))
	} else {
		return(col)
	}
})]

data.table::setcolorder(dataset, c("name", setdiff("name", colnames(dataset))))

dataset[, colnames(dataset) := lapply(.SD, function(x) {
	ifelse(is.na(x), 0, x)
})]

data.table::fwrite(dataset, "./parsed-food-data.csv")
