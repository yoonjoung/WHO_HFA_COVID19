# This creates shiny app to display women's access to methods indicators using PMA data 
# There are four parts in this document:
# 0. Database update 
# 1. USER INTERFACE 
# 2. SERVER
# 3. CREATE APP 

        # call relevant library before start
        library(shiny)
        
        library(plyr)
        library(dplyr)
        library(tidyr)
        library(tidyverse)
        library(plotly)
        
        library(lubridate)
        library(stringr)
        library(stringi)
        
        ## Libraries for radar chart
        library(viridis)
        library(patchwork)
        library(hrbrthemes)
        library(fmsb)
        library(colormap)
        
        date<-as.Date(Sys.time(	), format='%d%b%Y')

#******************************
# 0. Database update 
#******************************

#setwd("C:/Users/YoonJoung Choi/Dropbox/0 iSquared/iSquared_WHO/ACTA/4.ShinyApp")
#dir()

dta<-read.csv("summary_COVID19HospitalReadiness_Kenya_R1.csv")%>%
    mutate(
        module="Case Management",
        muduleno=1,
        dummy=0,
        #xsurvey=paste0(country, " ", year, "/", month),
        xsurvey=" ")%>%
    mutate_if(is.factor, as.character)

dta1<-dta%>%
    filter(group=="All" | group=="Level" | group=="Location" | group=="Sector" )%>%
    mutate_at(vars(starts_with("x")), 
              funs(ifelse(obs<20, NA, .)))

dta1county<-dta%>%
    filter(group=="County" | group=="County and Facility level" )

dta2<-read.csv("summary_CEHS_Kenya_R1.csv")%>%
    mutate(
        module="CEHS",
        muduleno=2, 
        dummy=0,
        #xsurvey=paste0(country, " ", year, "/", month),
        xsurvey=" ")%>%
    mutate_at(vars(starts_with("x")), 
              funs(ifelse(obs<20, NA, .)))%>%
    mutate_at(    
        vars(starts_with("staff_pct")), 
        funs(round(., 1)) )

dta3<-read.csv("summary_CommonFacilitySections_Kenya_R1.csv")%>%
    mutate(
        module="CommonFacilitySections",
        muduleno=NA, 
        dummy=0,
        #xsurvey=paste0(country, " ", year, "/", month),
        xsurvey=" "  )%>%
    mutate_at(vars(starts_with("x")), 
              funs(ifelse(obs<20, NA, .)))
    
dta4<-read.csv("summary_Community_Kenya_R1.csv")%>%
    mutate(
        module="Community",
        muduleno=3, 
        dummy=0,
        #xsurvey=paste0(country, " ", year, "/", month),
        xsurvey=" "  )%>%
    mutate_at(vars(starts_with("x")), 
              funs(ifelse(obs<20, NA, .)))

grouplist<-c("All", "Level", "Location", "Sector")

legendlist<-list(orientation="v", font=list(size=12), 
                xanchor = "left", x = 1.02, 
                yanchor = "center", y = 0.5)
xlist<-list(title = "", tickfont = list(size=12))
ylist<-list(title = "% of facilities", tickfont = list(size=12))
temp<-dta1%>%filter(group=="All")
obs1<-print(temp$obs)
temp<-dta2%>%filter(group=="All")
obs2<-print(temp$obs)
temp<-dta3%>%filter(group=="All")
obs3<-print(temp$obs)
temp<-dta4%>%filter(group=="All")
obs4<-print(temp$obs)

#******************************
# 1. USER INTERFACE 
#******************************

ui<-fluidPage(
    
    # Header panel 
    headerPanel("Health services in the context of the COVID-19 pandemic: Kenya"),

    # Title panel 
    titlePanel("Assessment of:"),
    titlePanel("A. COVID-19 case management capacity,"),
    titlePanel("B. Continuity of essential health services, and"),
    titlePanel("C. Community needs, perceptions and demand"),

    # Side panel: define input and output   
    sidebarLayout(
        fluid = TRUE,
        # Side panel for inputs: only ONE in this case
        sidebarPanel(
            style = "position:fixed;width:inherit;", 
            width = 2,
            selectInput("group", 
                        "Select analysis domain (applicable for module-specific tab only)",
                        choices = grouplist, 
                        selected = "All")
        ),
        
        # Main page for output display 
        mainPanel(
            width = 8,
            
            tabsetPanel(type = "tabs",
                tabPanel("Summary",       
                    br(),
                    h4(strong("Summary readiness scores to manage COVID-19 cases")),
                    h6(em(span(paste("Data come from", obs1, "sentinel level 4-6 facilities.")), style = "color:blue")),
                    plotlyOutput("plotA_radar"), 
                    h6("Scores are % of tracer items available at facilities.", align = "right"),
                    h6("The number of tracer items are noted in parentheses. For detailed list, see module specific tabs.", align = "right"), 
                    
                    h4(strong("Summary readiness scores to continue essential health services (EHS)")),
                    h6(em(span(paste("Data come from", obs2, "sentinel level 2-4 facilities.")), style = "color:blue")),
                    plotlyOutput("plotB_radar"), 
                    h6("Scores are % of tracer items available at facilities.", align = "right"),
                    h6("The number of tracer items are noted in parentheses. For detailed list, see module specific tabs.", align = "right"), 
                    
                    h4(strong("General vaccine readiness scores")),
                    h6(em(span(paste("Data come from", obs3, "sentinel level 2-6 facilities.")), style = "color:blue")),
                    plotlyOutput("plotAB_vaccine"), 
                    hr(), 
                    h6("Hover over to see data values and indicator definitions.")
                ),
                tabPanel("A: COVID-19 case management",       
                    br(),
                    h6(em(span(paste("Data come from", obs1, "sentinel level 4-6 facilities. Percent estimates suppressed when the number of facilities by analysis domain is less than 20.")), style = "color:blue")),
                    br(),
                    #h4(strong("Bed capacity and occupancy rate")),
                    #fluidRow(
                    #    splitLayout(cellWidths = c("50%", "50%"), 
                    #                plotlyOutput("plotA_beds"), plotlyOutput("plotA_occupancy"))),
                    h4(strong("Bed capacity")),
                    plotlyOutput("plotA_beds"),
                    h4(strong("Occupancy rate")),
                    plotlyOutput("plotA_occupancy"),
                    h4(strong("Oxygen source, distribution system, and supplies")),
                    plotlyOutput("plotA_oxygen"),
                    h4(strong("Availability of medicines")),
                    plotlyOutput("plotA_meds"),
                    h4(strong("Availability of supplies")),
                    plotlyOutput("plotA_supply"),
                    h4(strong("Availability of functioning equipment")),
                    plotlyOutput("plotA_equipment"),
                    hr(), 
                    h6("Hover over to see data values and indicator definitions.")
                ), 
                tabPanel("B: Continuity of EHS",       
                    br(),
                    h6(em(span(paste("Data come from", obs2, "sentinel level 2-4 facilities.")), style = "color:blue")),
                    br(),
                    h4(strong("Staff infection")),
                    verbatimTextOutput("text_staff_pct_covid_all"),
                    plotlyOutput("plotB_staff_infection"),
                    
                    h4(strong("Staff management and training")),
                    verbatimTextOutput("text_xhr_increase"),
                    verbatimTextOutput("text_xtraining_ppe"), 
                    plotlyOutput("plotB_staff_HR"),
                    
                    h4(strong(" Financial management")),
                    plotlyOutput("plotB_finance"),
                    
                    h4(strong("COVID-19 safe space & IPC")),                    
                    plotlyOutput("plotB_ipc"),
                    
                    h4(strong("Service delivery strategy modification and restoration plan")),
                    plotlyOutput("plotB_strategy"), 
                    
                    h4(strong("Changes in outpatient utilization & reasons")),                    
                    plotlyOutput("plotB_svc"),
                    
                    h4(strong("Management of suspected/confirmed COVID-19 cases: overall level and by item")),                    
                    plotlyOutput("plotB_covidpt"),
                    
                    h4(strong("Home-based self-isolation and care for mild COVID cases: overall level and by item")),                    
                    plotlyOutput("plotB_covidpthbsi"),
                    
                    hr(), 
                    h6("Hover over to see data values and indicator definitions.")

                ), 
                tabPanel("A & B: Vaccine readiness",       
                    br(),
                    h6(em(span(paste("Data come from", obs3, "sentinel level 2-6 facilities.")), style = "color:blue")), 
                    h4(strong("General vaccine readiness scores")),
                    plotlyOutput("plotAB_vaccinepattern")
                ),
                tabPanel("C: Community",       
                    br(),
                    h6(em(span(paste("Data come from", obs4, "community key informants.")), style = "color:blue")),
                    h4("-Under development-"),
                    hr(), 
                    h6("Hover over to see data values and indicator definitions.")
                ),
                tabPanel("METHODS",           
                    hr(),
                    h4(span("For survey methods, refer to the methodology tab in the chartbooks.", style = "color:blue")), 
                    hr(),
                    h4("Indicator definitions are available in the chartbooks."), 
                    h4("Questionnaires are available in the shared OneDrive."), 
                    h4("All materials are saved in the shared OneDrive."), 
                    br()
                )
            )
        )
    )
)


#******************************
# 2. SERVER
#******************************
server<-function(input, output) {
    
    ##### output: A. Hospital Case management #####

    output$plotA_radar <- renderPlotly({
        
        dtafig<-dta1%>%filter(country=="Kenya")%>%filter(group=="All")%>%
            mutate(
                Medicines  = xdrug_score, 
                Supplies   = xsupp_score,  
                Equipment  = xequip_allfunction_score, 
                Diagnostics= xdiagcovid_score, 
                IPC.Items = xipcitem_score, 
                PPE        = xppe_all_score
            )%>%
            select(Medicines, Supplies, Equipment, Diagnostics, IPC.Items, PPE)%>%
            mutate_if(is.character,as.numeric)
        
        plot_ly(
            type = 'scatterpolar',
            r =c(dtafig$Medicines , 
                 dtafig$Supplies , 
                 dtafig$Equipment , 
                 dtafig$Diagnostics , 
                 dtafig$IPC.Items , 
                 dtafig$PPE ),
            theta = c("Medicines(10)", "Supplies(5)", "Equipment(4)", "Diagnostics(3)", "IPC.Items(6)", "PPE(6)"),
            fill = 'toself'  )%>%
            layout(
                polar = list(radialaxis = list(visible = TRUE,
                                               range = c(0,100))) 
            )    
        
    })

    output$plotA_IMST <- renderPlotly({
        
        ylist<-list(title = "% of facilities", tickfont = list(size=12))
        xlist<-list(title = "", tickfont = list(size=12))
        legendlist<-list(orientation="v", font=list(size=12), 
                    xanchor = "left", x = 1.02, 
                    yanchor = "center", y = 0.5)
        
        dta1%>%filter(country=="Kenya")%>%filter(group=="All")%>%
            mutate(ximst = ximst - ximst_fun)%>%
            plot_ly(x=~xsurvey, 
                    y=~ximst, name="IMST", type = 'bar') %>%
            add_trace(y=~ximst_fun, name="IMST, functioning") %>%
            layout(title=" ", 
                   xaxis = xlist, yaxis = ylist,
                   legend=legendlist, 
                   barmode = "stack"
                   )
        
    })
    
    output$plotA_beds <- renderPlotly({    
    
        xlistbeds<-list(title = "Total number of beds among sentinel facilities", tickfont = list(size=12))
        ylistbeds<-list(title = "", tickfont = list(size=12))
        legendlistreverse<-list(orientation="v", font=list(size=12), 
                    xanchor = "left", x = 1.02, 
                    yanchor = "center", y = 0.5)

        fig0<- dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%        
            plot_ly(y=~grouplabel, type = 'bar', 
                    x=~ybed, name="beds, total") %>% 
            layout(title=" ",
                   xaxis = xlistbeds, yaxis = ylistbeds, barmode = "stack",
                    legend=legendlistreverse
                   )
        
        fig1<- dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%        
            mutate(ybed_cap_covid_mild = ybed_cap_covid - ybed_cap_covid_critical - ybed_cap_covid_severe)%>%
            plot_ly(y=~grouplabel, type = 'bar',
                    x=~ybed_cap_covid_mild, name="beds for non severe/critical COVID", marker = list(color = '#cf7078')) %>%
            add_trace(x=~ybed_cap_covid_severe, name="beds for severe COVID", marker = list(color = '#c34c56')) %>%  
            add_trace(x=~ybed_cap_covid_critical, name="beds for critical COVID", marker = list(color = '#b41f2c')) %>% 
            layout(title=" ",
                   xaxis = xlistbeds, yaxis = ylistbeds, barmode = "stack",
                    legend=legendlistreverse
                   )
        
        fig2<- dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%
            plot_ly(y=~grouplabel, type = 'bar', 
                    x=~ybed_cap_respiso_o2, name="beds for respiratory isolation", marker = list(color = '#54278f')) %>%
            add_trace(x=~ybed_convert_respiso, name="potential additional beds for respiratory isolation", marker = list(color = '#9e9ac8')) %>%  
            layout(title=" ",
                   xaxis = xlistbeds, yaxis = ylistbeds, barmode = "stack",
                   legend=legendlistreverse
                   )        
        
        fig3<- dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%
            plot_ly(y=~grouplabel, type = 'bar', 
                    x=~ybed_icu, name="ICU beds", marker = list(color = '#a63603')) %>%
            add_trace(x=~ybed_convert_icu, name="potential additional ICU beds", marker = list(color = '#fd8d3c')) %>% 
            layout(title=" ",
                   xaxis = xlistbeds, yaxis = ylistbeds, barmode = "stack",
                   legend=legendlistreverse
                   )        
        
        subplot(fig0, fig1, fig2, fig3, nrows=4, shareX=TRUE, titleX=TRUE, margin=0.04)%>%
            layout(
                xaxis = xlistbeds, yaxis = ylistbeds, legend=legendlistreverse
            )
        
               
    })
    
    output$plotA_occupancy <- renderPlotly({    

        ylist<-list(title = "% among beds, pooled across sentinel facilities", tickfont = list(size=12))
        xlist<-list(title = "", tickfont = list(size=12))
        
        dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%  
            plot_ly(x=~grouplabel, type = 'bar', 
                    y=  ~xocc_lastnight, name="Occupancy rate last night, out of total beds", 
                    text = ~xocc_lastnight, textfont = list(size=12, color="black"), textposition = 'outside') %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            add_trace(y=~xocc_lastnight_covid, name="COVID occupancy rate last night, out of total beds",
                      text = ~xocc_lastnight_covid, textfont = list(size=12, color="black"), textposition = 'outside',
                      marker = list(color = '#ef3b2c')) %>%
            add_trace(y=~xocc_lastmonth_covid, name="COVID occupancy rate last month, out of total beds",
                      text = ~xocc_lastmonth_covid, textfont = list(size=12, color="black"), textposition = 'outside',
                      marker = list(color = '#fc9272')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            add_trace(y=~xcovid_occ_lastnight, name="COVID occupancy rate last night, out of COVID beds",
                      text = ~xcovid_occ_lastnight, textfont = list(size=12, color="black"), textposition = 'outside',
                      marker = list(color = '#f16913')) %>%
            add_trace(y=~xcovid_occ_lastmonth, name="COVID occupancy rate last month, out of COVID beds",
                      text = ~xcovid_occ_lastmonth, textfont = list(size=12, color="black"), textposition = 'outside',
                      marker = list(color = '#fdae6b')) %>%
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    
    })    
    
    output$plotA_meds <- renderPlotly({    
            
        ylist<-list(title = "% of facilities", tickfont = list(size=12))
        xlist<-list(title = "", tickfont = list(size=12))
        
        dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%  
            plot_ly(x=~grouplabel, 
                      y=~xdrug_score, name="Average score", type = 'bar') %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xdrug__001, name="Epinephrine or norepinephrine", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xdrug__002, name="Ceftriaxone", marker = list(color = '#A4C7E1')) %>%   
            add_trace(y=~xdrug__003, name="Ampicillin", marker = list(color = '#B6D2E7')) %>%   
            add_trace(y=~xdrug__004, name="Azithromycin", marker = list(color = '#C5DBEC')) %>%   
            add_trace(y=~xdrug__005, name="Cistracurium", marker = list(color = '#D1E2F0')) %>%   
            add_trace(y=~xdrug__006, name="Haloperidol", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xdrug__007, name="Morphine", marker = list(color = '#A4C7E1')) %>%   
            add_trace(y=~xdrug__008, name="Heparin", marker = list(color = '#B6D2E7')) %>%   
            add_trace(y=~xdrug__009, name="Hydrocortisone or dexamethasone", marker = list(color = '#C5DBEC')) %>%   
            add_trace(y=~xdrug__010, name="Intravenous fluids", marker = list(color = '#D1E2F0')) %>%   
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xdrug_100, name="All items", marker = list(color = '#31a354')) %>%
            add_trace(y=~xdrug_50, name="Half of items", marker = list(color = '#a1d99b')) %>% 
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    })
    
    output$plotA_supply <- renderPlotly({    
            
        ylist<-list(title = "% of facilities", tickfont = list(size=12))
        xlist<-list(title = "", tickfont = list(size=12))
        
        dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>%  
            plot_ly(x=~grouplabel, 
                      y=~xsupp_score, name="Average score", type = 'bar') %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 

            add_trace(y=~xsupply__001, name="Syringes and needles", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xsupply__002, name="IV cannulas and giving sets", marker = list(color = '#A4C7E1')) %>%   
            add_trace(y=~xsupply__003, name="Gauze", marker = list(color = '#B6D2E7')) %>%   
            add_trace(y=~xsupply__004, name="5% Chlorhexidine gluconate", marker = list(color = '#C5DBEC')) %>%   
            add_trace(y=~xsupply__005, name="Sodium hypochlorite 4-6% Chlorine", marker = list(color = '#D1E2F0')) %>%   
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xsupp_100, name="All items", marker = list(color = '#31a354')) %>%
            add_trace(y=~xsupp_50, name="Half of items", marker = list(color = '#a1d99b')) %>% 
            
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    })    
    
    output$plotA_equipment <- renderPlotly({    
    
        ylist<-list(title = "% of facilities", tickfont = list(size=10))
        xlist<-list(title = "", tickfont = list(size=10))
        
        dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>% 
            plot_ly(x=~grouplabel,
                    y=~xequip_allfunction_score, name="All quantity functioning, % of tracer items", type = 'bar') %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xequip_allfunction__001, name="x-ray", marker = list(color = '#8db9d9')) %>%
            add_trace(y=~xequip_allfunction__002, name="pulse oxymeter", marker = list(color = '#A4C7E1')) %>%
            add_trace(y=~xequip_allfunction__003, name="ventilator, ICU", marker = list(color = '#B6D2E7')) %>%
            add_trace(y=~xequip_allfunction__004, name="non-invasive ventilator", marker = list(color = '#C5DBEC')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>%   
            
            add_trace(y=~xequip_allfunction_100, name="All quantity functioning, all tracer items", marker = list(color = '#31a354')) %>%
            add_trace(y=~xequip_allfunction_50, name="All quantity functioning, half of tracer items", marker = list(color = '#a1d99b')) %>% 
            
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    
    })  
    
    output$plotA_oxygen <- renderPlotly({    
    
        ylist<-list(title = "% of facilities", tickfont = list(size=10))
        xlist<-list(title = "", tickfont = list(size=10))
        
        dta1%>%filter(country=="Kenya")%>%filter(group==input$group)%>% 
            plot_ly(x=~grouplabel, type = 'bar',
                      y=~xoxygen_concentrator, name="Oxygen concentrator", marker = list(color = '#9970ab')) %>%
            add_trace(y=~xoxygen_bulk, name="External supply - bulk", marker = list(color = '#5aae61')) %>%
            add_trace(y=~xoxygen_cylinder, name="External supply - oxygen cylinders", marker = list(color = '#f46d43')) %>% 
            add_trace(y=~xoxygen_plant, name = "Liquid/PSA oxygen generator plat", marker = list(color = '#66c2a5')) %>%     
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xoxygen_dist, name="piped oxygen distribution (any)", marker = list(color = '#f16913')) %>%
            add_trace(y=~xoxygen_dist__er, name="piped oxygen distribution: ER", marker = list(color = '#fd8d3c')) %>%
            add_trace(y=~xoxygen_dist__icu, name="piped oxygen distribution: ICU", marker = list(color = '#fdae6b')) %>%
            add_trace(y=~xoxygen_dist__iso, name="piped oxygen distribution: Isolation room", marker = list(color = '#fdd0a2')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xo2supp_score, name="O2 supply average score (%, based on 4 tracer items)", marker = list(color = '#006d2c')) %>%
            add_trace(y=~xo2__cannula, name="Nasal cannula", marker = list(color = '#74c476')) %>%
            add_trace(y=~xo2__mask, name="Oxygen mask", marker = list(color = '#a1d99b')) %>%
            add_trace(y=~xo2__humidifier, name="Humidifier", marker = list(color = '#c7e9c0')) %>%
            add_trace(y=~xo2__flowmeter, name="Flowmeter (Thorpe tube)", marker = list(color = '#e5f5e0')) %>%

            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    
    })    
    
    
    ##### output: AB COMBINED data for common sections #####    
    
    output$plotAB_vaccine <- renderPlotly({   
    
        ylist<-list(title = "% of facilities", tickfont = list(size=10))
        xlist<-list(title = "", tickfont = list(size=10))
        
        dta3%>%filter(country=="Kenya")%>%filter(group=="All")%>%
            plot_ly(x=~xsurvey,type = "bar", 
                      y=~xvac_avfun_fridgetemp, name="functioning fridge with temp log") %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xvac_av_coldbox, name="cold box, available", marker = list(color = '#fdae6b')) %>%
            add_trace(y=~xvac_avfun_coldbox_all, name="cold box, available with full set of icepacks", marker = list(color = '#fd8d3c')) %>%
            add_trace(y=~xvac_avfun_coldbox_all_full, name="cold box, ready for outreach*", marker = list(color = '#f16913')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xvac_av_carrier, name="carrier, available", marker = list(color = '#a1d99b')) %>%
            add_trace(y=~xvac_avfun_carrier_all, name="carrier, available with full set of icepacks", marker = list(color = '#74c476')) %>%
            add_trace(y=~xvac_avfun_carrier_all_full, name="carrier, ready for outreach*", marker = list(color = '#41ab5d')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>%             

            add_trace(y=~xvac_av_outreach, name="cold box or carrier, available", marker = list(color = '#9e9ac8')) %>%
            add_trace(y=~xvac_avfun_outreach_all_full, name="cold box or carrier, ready for outreach*", marker = list(color = '#807dba')) %>%
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)

    })

    output$plotAB_vaccinepattern <- renderPlotly({   
    
        ylist<-list(title = "% of facilities", tickfont = list(size=10))
        xlist<-list(title = "", tickfont = list(size=10))

        dta3%>%filter(country=="Kenya")%>%filter(group==input$group)%>%
            plot_ly(x=~grouplabel,type = "bar", 
                      y=~xvac_avfun_fridgetemp, name="functioning fridge with temp log") %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xvac_av_coldbox, name="cold box, available", marker = list(color = '#fdae6b')) %>%
            add_trace(y=~xvac_avfun_coldbox_all, name="cold box, available with full set of icepacks", marker = list(color = '#fd8d3c')) %>%
            add_trace(y=~xvac_avfun_coldbox_all_full, name="cold box, ready for outreach*", marker = list(color = '#f16913')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xvac_av_carrier, name="carrier, available", marker = list(color = '#a1d99b')) %>%
            add_trace(y=~xvac_avfun_carrier_all, name="carrier, available with full set of icepacks", marker = list(color = '#74c476')) %>%
            add_trace(y=~xvac_avfun_carrier_all_full, name="carrier, ready for outreach*", marker = list(color = '#41ab5d')) %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>%             

            add_trace(y=~xvac_av_outreach, name="cold box or carrier, available", marker = list(color = '#9e9ac8')) %>%
            add_trace(y=~xvac_avfun_outreach_all_full, name="cold box or carrier, ready for outreach*", marker = list(color = '#807dba')) %>%

            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)

    })    
    
    ##### output: B. Summary #####
    
    output$plotB_radar <- renderPlotly({
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group=="All")%>%
            mutate(
                Medicines  = xdrug_score, 
                Supplies   = xsupp_score,  
                Diagnostics= xdiag_score,
                Safe = xsupp_score,    
                IPC.Training   = xtraining_score,
                IPC.Guidelines = xguideline_score, 
                PPE        = xppe_all_score
            )%>%
            select(Medicines, Supplies, Diagnostics, Safe, IPC.Training, IPC.Guidelines, PPE)%>%
            mutate_if(is.character,as.numeric)
        
        #dtafig<-as.vector(cbind(dtafig, dtafig[,1]))
        
        plot_ly(
            type = 'scatterpolar',
            r =c(dtafig$Medicines , 
                 dtafig$Supplies , 
                 dtafig$Diagnostics , 
                 dtafig$Safe , 
                 dtafig$IPC.Training , 
                 dtafig$IPC.Guidelines , 
                 dtafig$PPE ),
            theta = c("Medicines(17)", "Supplies(3)", "Diagnostics(10)", "COVID-19 safety measures(10)", "IPC.Training(5)", "IPC.Guidelines(6)", "PPE(6)"),
            fill = 'toself'  )%>%
            layout(
                polar = list(radialaxis = list(visible = TRUE,
                                               range = c(0,100))) 
            )    
        
    })

     ##### output: B. Staff #####
    
    output$text_staff_pct_covid_all <- renderText({
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group=="All")
        paste0("Among the sentinel sites, overall ", 
              as.character(mean(dtafig$staff_pct_covid_all)), 
              "% of staff were infected with COVID-19 during this quarter.")
    })
    
    output$text_xhr_increase <- renderText({
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group=="All")
        paste0("Among the sentinel sites, overall ", 
               as.character(mean(dtafig$xhr_increase)), 
              "% of facilities have taken measures to increase staff FTE.")
    }) 
    
    output$text_xtraining_ppe <- renderText({
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group=="All")
        paste0("Among the sentinel sites, overall ", 
               as.character(mean(dtafig$xtraining__002)), 
              "% of facilities have provided training on PPE use.")
    })     
    
    output$plotB_staff_infection <- renderPlotly({
        
        yliststaff<-list(title = "% of staff", tickfont = list(size=12))
        xliststaff<-list(title = "", tickfont = list(size=12))
        legendlist<-list(orientation="v", font=list(size=12), 
                    xanchor = "left", x = 1.02, 
                    yanchor = "center", y = 0.5)
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)

        dtafig%>% 
            plot_ly(x=~grouplabel, y = ~staff_pct_covid_all, type = 'bar', 
                        name = "All", 
                        marker = list(color = '#fdd0a2'),
                        text = ~staff_pct_covid_all, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~dummy, name = " ", marker = list(color = '#ffffff')) %>%
            
            add_trace(y = ~staff_pct_covid_md, 
                        name = "Medical doctors",
                        marker = list(color = '#d94801'),
                        text = ~staff_pct_covid_md, textfont = list(size=12) , textposition = 'outside') %>%
            add_trace(y = ~staff_pct_covid_nr, 
                        name = "Nursing personnel", 
                        marker = list(color = '#f16913'),
                        text = ~staff_pct_covid_nr, textfont = list(size=12) , textposition = 'outside') %>% 
            add_trace(y = ~staff_pct_covid_othclinical , 
                        name = "Other clinical staff", 
                        marker = list(color = '#fd8d3c'),
                        text = ~staff_pct_covid_othclinical, textfont = list(size=12) , textposition = 'outside') %>% 
            add_trace(y = ~staff_pct_covid_nonclinical , 
                        name = "Non-clinical staff", 
                        marker = list(color = '#fdae6b'),
                        text = ~staff_pct_covid_nonclinical, textfont = list(size=12) , textposition = 'outside') %>% 
            add_annotations(
                text = "Staff infected with COVID-19",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14))%>%
            layout(xaxis = xliststaff, yaxis = yliststaff, legend=legendlist)

    })        

    output$plotB_staff_HR <- renderPlotly({
        
        ylist<-list(title = "% of facilities", tickfont = list(size=12))
        xlist<-list(title = "", tickfont = list(size=12))
        legendlist<-list(orientation="v", font=list(size=12), 
                    xanchor = "left", x = 1.02, 
                    yanchor = "center", y = 0.5)
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)
        
        fig1 <- dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xhr_shift, type = 'bar', 
                        name = "Shifted assignment", 
                        marker = list(color = '#6baed6'),
                        text = ~xhr_shift, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xhr_increase, 
                        name = "Increased FTE",
                        marker = list(color = '#3182bd'),
                        text = ~xhr_increase, textfont = list(size=12) , textposition = 'outside') %>%
            add_annotations(
                text = "HR management measures",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         
        
        fig2 <- dtafig %>% 
            plot_ly(x=~grouplabel, y = ~xtraining, type = 'bar', 
                        name = "Any topic related with COVID-19", 
                        marker = list(color = '#74c476'),
                        text = ~xtraining, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xtraining__001, 
                        name = "ICP",
                        marker = list(color = '#31a354'),
                        text = ~xtraining__001, textfont = list(size=12) , textposition = 'outside') %>%
            add_trace(y = ~xtraining__002, 
                        name = "PPE",
                        marker = list(color = '#006d2c'),
                        text = ~xtraining__002, textfont = list(size=12) , textposition = 'outside') %>%
            add_annotations(
                text = "Staff Training on COVID-19",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         
        
        subplot(fig1, fig2, shareY=TRUE, titleY=FALSE, margin=0.04)%>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         
    })        
    

    ##### output: B. Finance #####

    output$plotB_finance <- renderPlotly({
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)

        fig1 <- dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xexempt_covid, type = 'bar', 
                        name = "COVID-19 services", 
                        marker = list(color = '#fdbe85'),
                        text = ~xexempt_covid, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xexempt_other, 
                        name = "Non COVID-19 services",
                        marker = list(color = '#fd8d3c'),
                        text = ~xexempt_other, textfont = list(size=12) , textposition = 'outside') %>%
            add_annotations(
                text = "User fee exemption",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         

        fig2 <- dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xfinance_salaryontime, type = 'bar', 
                        name = "Salary", 
                        marker = list(color = '#74c476'),
                        text = ~xfinance_salaryontime, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xfinance_ontime, 
                        name = "Salary and overtime, if applicable",
                        marker = list(color = '#31a354'),
                        text = ~xfinance_ontime, textfont = list(size=12) , textposition = 'outside') %>%
            add_annotations(
                text = "On-time payment",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         
        
        subplot(fig1, fig2, shareY=TRUE, margin=0.04)%>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)         
        
    })       
    

    ##### output: B. IPC #####        
    
    output$plotB_ipc <- renderPlotly({
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)
        
        fig1 <- dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xppe_all_100, type = 'bar', 
                        name = "All PPE tracer items", 
                        marker = list(color = '#fdbe85'),
                        text = ~xppe_all_100, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xppe_all__001, 
                        name = "Masks",
                        marker = list(color = '#fd8d3c'),
                        text = ~xppe_all__001, textfont = list(size=12) , textposition = 'outside') %>%
            add_trace(y = ~xppe_all__002, 
                        name = "Respirator", 
                        marker = list(color = '#e6550d'),
                        text = ~xppe_all__002, textfont = list(size=12) , textposition = 'outside') %>% 
            add_trace(y = ~xppe_all__003, 
                        name = "Gowns", 
                        marker = list(color = '#a63603'),
                        text = ~xppe_all__003, textfont = list(size=12) , textposition = 'outside') %>%             
            add_annotations(
                text = "PPE provision to all relevant staff",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)
        
        fig2 <- dtafig %>% 
            plot_ly(x=~grouplabel, y = ~xsafe, type = 'bar', 
                        name = "Any measure", 
                        marker = list(color = '#74c476'),
                        text = ~xsafe, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xsafe__001, 
                        name = "Triage",
                        marker = list(color = '#31a354'),
                        text = ~xsafe__001, textfont = list(size=12) , textposition = 'outside') %>%
            add_trace(y = ~xsafe__002, 
                        name = "Isolation",
                        marker = list(color = '#006d2c'),
                        text = ~xsafe__002, textfont = list(size=12) , textposition = 'outside') %>%
            add_annotations(
                text = "Implementation of COVID-19 safe environment measures",
                x = 0.5, y = 1, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)  
        
        subplot(fig1, fig2, shareY=TRUE, titleY=FALSE, margin=0.04)%>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)
        
    })        
    
    ##### output: B. service delivery and utilization #####        
    
    output$plotB_strategy <- renderPlotly({
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)
        
        dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xstrategy_reduce, type = 'bar', 
                    name = "Changed service delivery strategy/platform to reduce service provision",
                    text = ~xstrategy_reduce, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xout_decrease, 
                    name = "Decreased out-reach service provision", 
                    text = ~xout_decrease, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xresto, 
                    name = "Developed catch-up plans for missed appointments",
                    text = ~xresto, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)

    })            
    
    output$plotB_svc <- renderPlotly({
        
        dtafig<-dta2%>%filter(country=="Kenya")%>%filter(group==input$group)
        
        fig1 <- dtafig%>% 
            plot_ly(x=~grouplabel, y = ~xopt_increase,  type = 'bar', 
                        name = "Increase in 1+ services",
                        marker = list(color = '#fdbe85'),
                        text = ~xopt_increase, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~dummy, name = " ", marker = list(color = '#ffffff')) %>%
            add_trace(y = ~xopt_increase_reason_covidnow, 
                        name = "Due to current outbreak",
                        marker = list(color = '#fd8d3c'),
                        text = ~xopt_increase_reason_covidnow, textfont = list(size=12) , textposition = 'outside') %>%
            add_trace(y = ~xopt_increase_reason_covidafter, 
                        name = "Due to catch up after a completed wave", 
                        marker = list(color = '#e6550d'),
                        text = ~xopt_increase_reason_covidafter, textfont = list(size=12) , textposition = 'outside') %>% 
            add_annotations(
                text = "Increased OPT visits & reasons",
                x = 0.5, y = 1.02, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)
        
        fig2 <- dtafig %>% 
            plot_ly(x=~grouplabel, y = ~xopt_decrease,   type = 'bar', 
                    name = "Decrease in 1+ services",
                    marker = list(color = '#c7e9c0'), 
                    text = ~xopt_decrease, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~dummy, name = " ", marker = list(color = '#ffffff')) %>%
            add_trace(y = ~xopt_decrease_reason_comdemand, 
                    name = "Due to community demand change",
                    marker = list(color = '#a1d99b'), 
                    text = ~xopt_decrease_reason_comdemand, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xopt_decrease_reason_enviro, 
                    name = "Due to lockdown",
                    marker = list(color = '#74c476'), 
                    text = ~xopt_decrease_reason_enviro, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xopt_decrease_reason_intention, 
                    name = "Due to intentionally reduced service provision",
                    marker = list(color = '#41ab5d'), 
                    text = ~xopt_decrease_reason_intention, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_trace(y = ~xopt_decrease_reason_disruption, 
                    name = "Due to disrupted servie capacity",
                    marker = list(color = '#238b45'), 
                    text = ~xopt_decrease_reason_disruption, textfont = list(size=12, color="black"), textposition = 'outside')%>%
            add_annotations(
                text = "Decreased OPT visits & reasons",
                x = 0.5, y = 1.02, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 14)
                ) %>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)  
        
        subplot(fig1, fig2, shareY=TRUE, titleY=FALSE, margin=0.04)%>%
            layout(xaxis = xlist, yaxis = ylist, legend = legendlist)
    })  

    output$plotB_covidpt <- renderPlotly({    

        dta2%>%filter(country=="Kenya")%>%filter(group==input$group)%>%  
            plot_ly(x=~grouplabel, type = 'bar', 
                      y=~xcvd_pt, name="Had suspected/confirmed COVID-19 patients") %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xcvd_pt__001, name="consultation in a separate room", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xcvd_pt__002, name="Checked for COVID-19 symptoms", marker = list(color = '#A4C7E1')) %>%   
            add_trace(y=~xcvd_pt__003, name="Measured O2 saturation", marker = list(color = '#B6D2E7')) %>%   
            add_trace(y=~xcvd_pt__004, name="Referred the patient to specialized care", marker = list(color = '#C5DBEC')) %>%   
            add_trace(y=~xcvd_pt__005, name="Performed diagnostic test", marker = list(color = '#D1E2F0')) %>%   
            add_trace(y=~xcvd_pt__006, name="Sent mild patients for home-based self0isolation", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xcvd_pt__007, name="teleconsultation before facility visit", marker = list(color = '#A4C7E1')) %>%   
            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    })    
        
    output$plotB_covidpthbsi <- renderPlotly({    

        dta2%>%filter(country=="Kenya")%>%filter(group==input$group)%>%  
            plot_ly(x=~grouplabel, 
                      y=~xcvd_pthbsi, name="Sent mild COVID patients for HBSI", type = 'bar') %>%
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 
            
            add_trace(y=~xcvd_pthbsi__001, name="Reported to county/sub-county authority", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~xcvd_pthbsi__002, name="Followed up remotely", marker = list(color = '#A4C7E1')) %>%   
            add_trace(y=~xcvd_pthbsi__003, name="Provided remote consultation", marker = list(color = '#B6D2E7')) %>%   
            add_trace(y=~xcvd_pthbsi__004, name="Visited patients at home", marker = list(color = '#C5DBEC')) %>%   
            add_trace(y=~xcvd_pthbsi__005, name="Arranged facility visit", marker = list(color = '#D1E2F0')) %>%   
            add_trace(y=~xcvd_pthbsi__006, name="Provided safety instructions for household members", marker = list(color = '#8db9d9')) %>%   
            add_trace(y=~dummy, name = " ", marker = list(color = '#ffffff')) %>% 

            layout(xaxis = xlist, yaxis = ylist, legend=legendlist)
    })

}       

#******************************
# 3. CREATE APP 
#******************************

 shinyApp(ui = ui, server = server)