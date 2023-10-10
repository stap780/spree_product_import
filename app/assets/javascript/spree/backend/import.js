document.addEventListener("spree:load", function() {
    console.log('import load');

    function getStrategy(){
        var strategy = $("#product_import_strategy").val();
        showUniq(strategy);
    }
    function showUniq(value){
        if (value == 'product'){
            $("#product_import_uniq_field option").show();
            $("#product_import_uniq_field option[value='variant#id']").hide();
            $("#product_import_uniq_field option[value='variant#sku']").hide();
        }
        if (value == 'product_variant'){
            $("#product_import_uniq_field option").show();
            $("#product_import_uniq_field option[value='product#sku']").hide();
        }
    }
    getStrategy();
    $("#product_import_strategy").change(function(){
        getStrategy();
    });
})
