/*
    This component is for the questionnaire form
*/

//Angular Imports
import { FormGroup, FormBuilder, Validators, FormArray, ValidatorFn } from '@angular/forms';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';

//JavaScript Imports
import { Subscription } from 'rxjs/Subscription';

//Local Imports
import { Questionnaire } from '../../FHIR/Questionnaire';
import { FhirService } from '../../FHIR/fhir.service'
import { environment } from '../../environments/environment';
import { QuestionnaireResponse } from '../../FHIR/QuestionnaireResponse';

//JS function to remove unused data
function clean(key, value) {
    return (value == (null || "")) ? undefined : value;
}

@Component({

    moduleId: module.id,
    templateUrl: 'questionnaireResponse-form.component.html'
})
export class QuestionnaireResponseFormComponent implements OnInit {

    //The Form
    questionnaireResponseForm: FormGroup;

    //FHIR Objects
    questionnaire: Questionnaire;
    questionnaireResponse: QuestionnaireResponse[];

    //HTML Variables
    pageTitle: string = 'Questionnaire Form';
    instructions: string = 'Please fill out the questionnaire below';
    saveText: string = 'Submit';

    //Error Handling
    errorMessage: string;

    //ID Handling
    id: String;
    pid: string;
    private sub: Subscription;

    //Flags
    gotData: boolean

    constructor(private _route: ActivatedRoute,
        private _router: Router,
        private fhirService: FhirService,
        private _fb: FormBuilder
    ) { }

    //This method runs before the page is loaded
    ngOnInit(): void {

        //Get the questionnaire and patient IDs from the URL
        this.sub = this._route.params.subscribe(
            params => {

                let id = params['id'];
                let pid = params['pid'];
                this.pid = pid;
                this.id = id;

                //Get the questionnaire JSON
                this.fhirService.getOneFhirObject('/' + this.id, environment.apiUrl_questionnaire)
                    .subscribe(questionnaire => {

                        this.questionnaire = questionnaire;

                        //Setup the questionnaire response form
                        this.questionnaireResponseForm = this._fb.group({

                            resourceType: ["QuestionnaireResponse"],
                            id: [this.pid + '_' + this.id],
                            subject: this._fb.group({
                                reference: [this.pid],
                                display: []
                            }),
                            item: this._fb.array([])
                        });

                        //Start adding questionnaire items
                        this.addItem(this.questionnaire.item.length - 1);

                        //Tell the HTML page that it is safe to load
                        //This prevents undefined errors
                        this.gotData = true;

                    },
                    error => this.errorMessage = <any>error);

            });
    }

    //This method creates a new item for the form from the questionnaire object
    //  i: The questionnaire item index
    initItem(i: number) {

        return this._fb.group({

            linkId: this.questionnaire.item[i].linkId,
            text: this.questionnaire.item[i].text,
            answer: this._fb.array([
                this.initAnswer(i)
            ])
        });
    }

    //This method creates a new answer object
    //  i: The questionnaire item index
    initAnswer(i: number) {

        //Return the correct answer type needed
        if (this.questionnaire.item[i] != undefined) {

            if (this.questionnaire.item[i].type === 'choice') {

                return this._fb.group({
                    valueString: ['', [Validators.required]],
                })

            } else if (this.questionnaire.item[i].type === 'boolean') {

                return this._fb.group({
                    valueBoolean: ['', [Validators.required]],
                })

            } else if (this.questionnaire.item[i].type === 'quantity') {

                return this._fb.group({
                    valueQuantity: ['', [Validators.required]],
                })

            } else {

                return this._fb.group({
                    valueString: [''],
                    valueBoolean: [''],
                    valueQuantity: [''],
                    valueDate: ['']
                })
            }
        }

    }

    //This method adds the item to the form
    //  numQuestions: The number of questions on the questionnaire
    addItem(numQuestions: number) {

        for (var i = 0; i <= numQuestions; i++) {
            const control = <FormArray>this.questionnaireResponseForm.controls['item'];
            control.push(this.initItem(i));
        }
    }

    //This method runs when the user leaves the page
    ngOnDestroy() {

        this.sub.unsubscribe();
    }

    //This method controls the back button
    onBack(): void {

        this._router.navigate(['/questionnaires/' + this.pid]);
    }

    //This method saves the new questionnaire response
    //  questionnaireResponseForm: The form the user filled out
    save(questionnaireResponseForm: FormGroup) {

        //Disable the form to prevent duplicate posts
        this.questionnaireResponseForm.disable()

        //insert the question text into the answers 
        for (var i = 0; i < this.questionnaire.item.length; i++) { questionnaireResponseForm.value.item[i].text = this.questionnaire.item[i].text; }

        //Convert valueQuantity into Quantity objects
        for (var r = 0; r < this.questionnaire.item.length; r++) {

            if (questionnaireResponseForm.value.item[r].answer[0].valueQuantity != undefined) {

                if (questionnaireResponseForm.value.item[r].answer[0].valueQuantity == 0) {

                    questionnaireResponseForm.value.item[r].answer[0].valueQuantity = { value: '0' }

                } else {

                    questionnaireResponseForm.value.item[r].answer[0].valueQuantity = { value: questionnaireResponseForm.value.item[r].answer[0].valueQuantity }
                }
            }
        }

        //post the questionnaire response
        this.fhirService.postFhirObject(JSON.stringify(questionnaireResponseForm.value, clean), environment.apiUrl_questionnaireResponse)
            .subscribe(questionnaireResponse => { this.questionnaireResponse = questionnaireResponse; this._router.navigate(['/questionnaires/' + this.pid]); },
            error => this.errorMessage = <any>error);

    }
}
