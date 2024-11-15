let Chars = {}
let CreatingMenu = false
let tebexLink = ""

$(function(){
    $.post(`https://${GetParentResourceName()}/loaded`)
    const element = document.querySelector(".characters-box");

    element.addEventListener('wheel', (event) => {
        event.preventDefault();

        element.scrollBy({
            left: event.deltaY < 0 ? -60 : 60,
        });
    });
    
    $(document).on("click", ".characters-box .box-wrapper .box.haschar .click-box", function(){
        if ($(this).parent().hasClass("active")) return

        let license = $(this).parent().data("license")
        $(".box.haschar").removeClass("active")
        $(this).parent().addClass("active")
        $.post(`https://${GetParentResourceName()}/playerSelected`, JSON.stringify(license))

        for (let i = 0; i < Chars.length; i++) {
            if (Chars[i].citizenid == license || Chars[i].identifier == license){
                let firstname = JSON.parse(Chars[i].charinfo).firstname || Chars[i].firstname
                let lastname = JSON.parse(Chars[i].charinfo).lastname || Chars[i].lastname
                let gender = Chars[i].charinfo.gender == 0 ? "MALE" : "FEMALE" || Chars[i].chardata[i].sex == "m" ? "MALE" : "FEMALE" 

                $(".char-selected-box .name").html(`<span>${firstname}</span> ${lastname}`)
                $(".char-selected-box .gender").html(gender)
            }
        }
    })
    
    $(document).on("click", ".characters-box .create-btn", function(){
        $(".box.haschar").removeClass("active")
        $.post(`https://${GetParentResourceName()}/playCreateAnimation`)
        $(".characters-box").fadeOut(100);
        $(".char-selected-box").fadeOut(100);

        setTimeout(() => {
            $(".create-box").fadeIn(100);
            $(".create-box").css("display", "flex");
            CreatingMenu = true
        }, 1000);
    })
    
    $(document).on("click", ".create-box .cancel.btn", function(){
        $.post(`https://${GetParentResourceName()}/stopCreateAnim`)
        $(".create-box").fadeOut(100);

        setTimeout(() => {
            $(".characters-box").fadeIn(100);
            $(".char-selected-box").fadeIn(100);
            CreatingMenu = false
        }, 1000);
    })

    $(document).on("input", "#firstname-input", function(){
        let data = $("#firstname-input").val()

        if (data.length > 15){
            $("#firstname-input").val(data.slice(0, 15))
        }
    })

    $(document).on("input", "#lastname-input", function(){
        let data = $("#lastname-input").val()

        if (data.length > 15){
            $("#lastname-input").val(data.slice(0, 15))
        }
    })

    $(document).on("input", "#nationality-input", function(){
        let data = $("#nationality-input").val()

        if (data.length > 20){
            $("#nationality-input").val(data.slice(0, 20))
        }
    })

    $(document).on("input", "#gender-input", function(){
        let data = $("#gender-input").val()
        $.post(`https://${GetParentResourceName()}/genderUpdate`, JSON.stringify(data))
    })
    
    $(document).on("click", ".create-box .create.btn", function(){
        let gender = $("#gender-input").val()
        let firstname = $("#firstname-input").val()
        let lastname = $("#lastname-input").val()
        let nationality = $("#nationality-input").val()
        let dob = $("#dob-input").val()

        if (firstname.length < 3 || firstname.length > 15) {
            $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Firstname must be between 3 and 15 characters"))
            return
        }else if (lastname.length < 3 || lastname.length > 15) {
            $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Lastname must be between 3 and 15 characters"))
            return
        }else if (nationality.length < 2 || nationality.length > 20) {
            $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Nationality must be between 2 and 20 characters"))
            return
        }

        if (gender && firstname && lastname && nationality && dob){
            $.post(`https://${GetParentResourceName()}/createCharacter`, JSON.stringify({
                gender: gender,
                firstname: firstname,
                lastname: lastname,
                nationality: nationality,
                dob: dob
            }), function(cb){
                if (cb){
                    $("body").fadeOut(100);
                }else{
                    $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Something went wrong"))
                }
            })
        }else{
            $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Please fill all the fields"))
        }
    })

    $(document).on("click", ".characters-box .box-wrapper .play-btn.btn", function(){
        $.post(`https://${GetParentResourceName()}/selectCharacter`, JSON.stringify($(this).data("license")))
        $("body").fadeOut(100);
    })

    $(document).on("click", ".locked-btn", function(){
        $(".toaster-wrapper input").val("");
        $(".toaster-wrapper").fadeIn(200);
        $(".toaster-wrapper").css("display", "flex");
    })
    
    $(document).on("click", ".close-box", function(){
        $(".toaster-wrapper").fadeOut(200);
    })
    
    $(document).on("click", ".submit", function(){
        if ($(".toaster-wrapper input").val() == "" || !$(".toaster-wrapper input").val()) return

        $.post(`https://${GetParentResourceName()}/submitCode`, JSON.stringify($(".toaster-wrapper input").val()), function(cb){
            if (cb){
                let payedSlots = cb.payedSlots - cb.purchasedSlots
                let lockedSlots = cb.slots - payedSlots
                createAll(lockedSlots, Chars, cb.slots)

                $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Slot purchased"))
                $(".toaster-wrapper").fadeOut(200);
            }else{
                $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("This code is used or not valid"))
            }
        })
    })

    $(document).on("mouseover", ".characters-box .box-wrapper .box.haschar", function(){
        $.post(`https://${GetParentResourceName()}/playHoverAnimation`, JSON.stringify($(this).data("license")))
    })
    
    $(document).on("mouseout", ".characters-box .box-wrapper .box.haschar", function(){
        $.post(`https://${GetParentResourceName()}/hoverOut`)
    })

    $(document).on("click", ".delete-btn", function(){
        $(".characters-box").fadeOut(100);
        $(".char-selected-box").fadeOut(100);

        $.post(`https://${GetParentResourceName()}/deleteChar`, JSON.stringify($(this).data("license")), function(cb){
            if (cb){
                let payedSlots = cb.payedSlots - cb.purchasedSlots
                let lockedSlots = cb.slots - payedSlots
                Chars = Object.values(cb.charData)
                createAll(lockedSlots, Chars, cb.slots)
            }else{
                $.post(`https://${GetParentResourceName()}/notify`, JSON.stringify("Something went wrong"))
            }
        })
    })

    window.addEventListener("message", function(event){
        let data = event.data;

        if(data.action == "open"){
            $(".loading").show();
            $("body").fadeIn();
        }

        if(data.action == "sendData"){
            let payedSlots = data.payedSlots - data.purchasedSlots
            let lockedSlots = data.slots - payedSlots
            console.log(payedSlots, lockedSlots, data.payedSlots, data.purchasedSlots)
            Chars = Object.values(data.charData)
            createAll(lockedSlots, Chars, data.slots)
        }
    })

    document.onkeyup = function (data) {
        if (data.which == 27) {
            if (CreatingMenu){
                $.post(`https://${GetParentResourceName()}/stopCreateAnim`)
                $(".create-box").fadeOut(100);
            }
        }
    };
})

function createAll(lockedSlots, chardata, slots){
    if (!chardata) {
        $(".characters-box").hide()
        $(".create-box").show()

        $.post(`https://${GetParentResourceName()}/playCreateAnimation`, JSON.stringify({}), function(){
            $(".loading").fadeOut(100);
        })
    }else{
        $(".characters-box .box-wrapper").html("");

        $.post(`https://${GetParentResourceName()}/playIdleAnimation`, JSON.stringify(chardata), function(){
            for (let i = 0; i < slots; i++) {
                if (i < lockedSlots){
                    $(".characters-box .box-wrapper").append(`
                    <div class="box empty">
                        <div class="icons">
                            <div class="top"><img src="assets/top.png"></div>
                            <div class="bottom"><img src="assets/bottom.png"></div>
                        </div>

                        <div class="name-box">
                            <div class="name-wrap">
                                <div class="name">CREATE</div>
                                <div class="surname">CHARACTER</div>
                            </div>
                        </div>

                        <div class="btn create-btn">
                            <svg width="18" height="17" viewBox="0 0 18 17" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path d="M18 8.71429C18 9.26657 17.5523 9.71429 17 9.71429H11.2857C10.7334 9.71429 10.2857 10.162 10.2857 10.7143V16C10.2857 16.5523 9.838 17 9.28571 17H8.71429C8.162 17 7.71429 16.5523 7.71429 16V10.7143C7.71429 10.162 7.26657 9.71429 6.71429 9.71429H1C0.447716 9.71429 0 9.26657 0 8.71429V8.28571C0 7.73343 0.447715 7.28572 1 7.28572H6.71428C7.26657 7.28572 7.71429 6.838 7.71429 6.28572V0.999999C7.71429 0.447714 8.162 0 8.71429 0H9.28571C9.838 0 10.2857 0.447715 10.2857 1V6.28572C10.2857 6.838 10.7334 7.28572 11.2857 7.28572H17C17.5523 7.28572 18 7.73343 18 8.28572V8.71429Z" fill="white"/>
                            </svg>
                        </div>
                    </div>
                    `)
                }else{
                    $(".characters-box .box-wrapper").append(`
                    <div class="box locked">
                        <div class="icons">
                            <div class="top"><img src="assets/top.png"></div>
                            <div class="bottom"><img src="assets/bottom.png"></div>
                        </div>

                        <div class="name-box">
                            <div class="name-wrap">
                                <div class="name">PURCHASE</div>
                                <div class="surname">SLOT</div>
                            </div>
                        </div>
        
                        <div class="btn locked-btn">
                            <svg width="16" height="18" viewBox="0 0 16 18" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path fill-rule="evenodd" clip-rule="evenodd" d="M2.66667 5.4C2.66667 3.96783 3.22857 2.59432 4.22876 1.58162C5.22896 0.568927 6.58551 0 8 0C9.41449 0 10.771 0.568927 11.7712 1.58162C12.7714 2.59432 13.3333 3.96783 13.3333 5.4H14.2222C14.6937 5.4 15.1459 5.58964 15.4793 5.92721C15.8127 6.26477 16 6.72261 16 7.2V16.2C16 16.6774 15.8127 17.1352 15.4793 17.4728C15.1459 17.8104 14.6937 18 14.2222 18H1.77778C1.30628 18 0.854097 17.8104 0.520699 17.4728C0.187301 17.1352 0 16.6774 0 16.2V7.2C0 6.72261 0.187301 6.26477 0.520699 5.92721C0.854097 5.58964 1.30628 5.4 1.77778 5.4H2.66667ZM8 1.8C8.94299 1.8 9.84736 2.17928 10.5142 2.85442C11.181 3.52955 11.5556 4.44522 11.5556 5.4H4.44444C4.44444 4.44522 4.81905 3.52955 5.48584 2.85442C6.15264 2.17928 7.05701 1.8 8 1.8ZM9.77778 10.8C9.77777 11.116 9.69562 11.4263 9.53959 11.7C9.38356 11.9736 9.15914 12.2008 8.88889 12.3588V13.5C8.88889 13.7387 8.79524 13.9676 8.62854 14.1364C8.46184 14.3052 8.23575 14.4 8 14.4C7.76425 14.4 7.53816 14.3052 7.37146 14.1364C7.20476 13.9676 7.11111 13.7387 7.11111 13.5V12.3588C6.77221 12.1607 6.50736 11.8549 6.35761 11.4888C6.20786 11.1227 6.18159 10.7168 6.28288 10.3341C6.38416 9.95139 6.60734 9.6132 6.91781 9.37199C7.22827 9.13077 7.60866 9.00002 8 9C8.4715 9 8.92368 9.18964 9.25708 9.52721C9.59048 9.86477 9.77778 10.3226 9.77778 10.8Z" fill="white"/>
                            </svg>
                        </div>
                    </div>
                    `)
                }
            }

            for (let i = 0; i < chardata.length; i++) {
                $(`.characters-box .box-wrapper .box:nth-child(${i + 1})`).removeClass("locked")
                $(`.characters-box .box-wrapper .box:nth-child(${i + 1})`).removeClass("empty")
                $(`.characters-box .box-wrapper .box:nth-child(${i + 1})`).addClass("haschar")
                $(`.characters-box .box-wrapper .box:nth-child(${i + 1})`).data("license", chardata[i].citizenid || chardata[i].identifier)

                let charinfo = JSON.parse(chardata[i].charinfo) || ""

                $(`.characters-box .box-wrapper .box:nth-child(${i + 1})`).html(`
                    <div class="icons">
                        <div class="top"><img src="assets/top.png"></div>
                        <div class="bottom"><img src="assets/bottom.png"></div>
                    </div>

                    <div class="click-box"></div>
    
                    <div class="name-box">
                        <div class="identifier">${chardata[i].identifier || chardata[i].citizenid}</div>
                        <div class="name-wrap">
                            <div class="name">${charinfo.firstname || chardata[i].firstname}</div>
                            <div class="surname">${charinfo.lastname || chardata[i].lastname}</div>
                        </div>
                    </div>
    
                    <div class="delete-btn" data-license="${chardata[i].identifier || chardata[i].citizenid}">DELETE</div>

                    <div class="btn play-btn" data-license="${chardata[i].identifier || chardata[i].citizenid}">
                        <svg width="15" height="20" viewBox="0 0 15 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M-0.000104948 1.00057L-0.000105735 19.0006C0.000465508 19.1828 0.0507289 19.3614 0.145272 19.5172C0.239816 19.673 0.375059 19.8001 0.536447 19.8848C0.697834 19.9694 0.879254 20.0085 1.06118 19.9977C1.2431 19.9869 1.41864 19.9267 1.56889 19.8236L14.5689 10.8236C15.1079 10.4506 15.1079 9.55257 14.5689 9.17857L1.5689 0.178573C1.41895 0.074398 1.24333 0.0133073 1.0611 0.00193832C0.878874 -0.00943065 0.697017 0.029357 0.535288 0.114087C0.373559 0.198817 0.238141 0.326249 0.143751 0.482537C0.0493612 0.638826 -0.00039295 0.817993 -0.000104948 1.00057ZM1.56889 9.5L1.99989 17.0926L1.99989 2.90857L1.56889 9.5Z" fill="white"/>
                        </svg>
                    </div>
                `)
            }
        })
    }

    setTimeout(() => {
        $(".loading").fadeOut(100);
        $(".characters-box").fadeIn(100);
        $(".char-selected-box").fadeIn(100);
        CreatingMenu = false
    }, 1000);
}