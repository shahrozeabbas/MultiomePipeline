
working_dir <- '/data/CARD_singlecell/snakemake_multiome/'; setwd(working_dir)

source('scripts/main/load_packages.r')

future::plan('multicore', workers=snakemake@threads)
options(future.globals.maxSize=50 * 1000 * 1024^2)


object.list <- readRDS(snakemake@input[['seurat_object']])

s.genes <- cc.genes$s.genes
g2m.genes <- cc.genes$g2m.genes

noise <- c('percent.mt', 'percent.rb', 'nFeature_RNA', 'nCount_RNA', 'doublet_scores', 'G2M.Score', 'S.Score')

object.list <- sapply(object.list, function(object) {
    
    genes <- rownames(object)
    DefaultAssay(object) <- 'RNA'
    
    object %>% 
    
        NormalizeData() %>% 
        CleanVarGenes(nHVG=2000) %>% 
        ScaleData(features=genes, verbose=FALSE) %>% 
        CellCycleScoring(s.features=s.genes, g2m.features=g2m.genes)

}, simplify=FALSE)

features <- object.list %>% SelectIntegrationFeatures(nfeatures=5000)

object.list <- sapply(object.list, function(object) {
    
    object %>% 
      ScaleData(features=features, vars.to.regress=noise, verbose=FALSE) %>% 
      RunPCA(features=features, verbose=FALSE)
      
}, simplify=FALSE)

anchors <- object.list %>% FindIntegrationAnchors(anchor.features=features, reduction='rpca', k.anchor=7, scale=FALSE, dims=1:50)
object <- IntegrateData(anchorset=anchors, new.assay.name='integrated.rna', k.weight=50, dims=1:50)


saveRDS(object, snakemake@output[['seurat_object']])




