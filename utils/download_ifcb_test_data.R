# pak::pkg_install("EuropeanIFCBGroup/iRfcb")

library(iRfcb)

data_dir <- fs::path("data", "data_roi")

ifcb_download_test_data(dest_dir = data_dir, max_retries = 10L)
