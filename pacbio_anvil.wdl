version 1.0

workflow Test {
  input {
    Array[String] table_names
    String model_url
    String workspace_name
    String workspace_namespace
  }

  call export_tables{
    input:
        table_names=table_names,
        model_url=model_url,
        workspace_name=workspace_name,
        workspace_namespace=workspace_namespace,
  }

  call parse_tsv {
    input:
        aligned_nanopore=export_tables.aligned_nanopore
  }
}

task parse_tsv {
    input {
        File aligned_nanopore 
    }

    command {
    python <<CODE
    import pandas as pd
    df = pd.read_csv(${aligned_nanopore},sep="\t")
    df.to_json("nanopore.json",orient="records")
    CODE
    }

    output {
        File nanopore_json = "nanopore.json"
    }
    runtime {
        docker: "quay.io/biocontainers/pandas:2.2.1"
    }
}

task export_tables {
    input {
        Array[String] table_names
        String model_url
        String workspace_name
        String workspace_namespace
    }

    command <<<
        Rscript -e "\
        model <- AnvilDataModels::json_to_dm('~{model_url}'); \
        tables <- readLines('~{write_lines(table_names)}'); \
        for (t in tables) { \
            dat <- AnVIL::avtable(t, name='~{workspace_name}', namespace='~{workspace_namespace}'); \
            readr::write_tsv(dat, paste0(t,'_noIntersect', '.tsv')); \
            ordered_cols <- intersect(names(model[[t]]), names(dat)); \
            dat <- dat[,ordered_cols]; \
            readr::write_tsv(dat, paste0(t, '.tsv')); \
        } \
        "
    >>>

    output {
        Array[File] tables = glob("*.tsv")
        File aligned_nanopore = "aligned_nanopore.tsv"
    }

    runtime {
        docker: "uwgac/anvil-util-workflows:0.5.0"
    }
}

