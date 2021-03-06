import { Injectable } from '@angular/core';
import { Http, Response } from '@angular/http';

import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/catch';
import 'rxjs/add/operator/map';

@Injectable()
export class MssqlService {

    constructor(private http: Http) { }

    getBatchData() {
        let url = '/sql/getBatches';
        return this.http.get(url)
            .map((resp: Response) => resp.json())
            .catch(this.handleError)
    }

    getBatchDetail(batchNumber: string) {
        let url = '/sql/getBatchDetail/' + batchNumber;
        return this.http.get(url)
            .map((resp: Response) => resp.json())
            .catch(this.handleError)
    }

    releaseBatch(batchNumber: string, user: string){
        let body = {user: user};
        let url = '/sql/releaseBatch/' + batchNumber;
        return this.http.put(url, body)
            .map((resp: Response) => resp.json())
            .catch(this.handleError)
    }

    rejectBatch(batchNumber: string, user: string){
        let body = {user: user};
        let url = '/sql/rejectBatch/' + batchNumber;
        return this.http.put(url, body)
            .map((resp: Response) => resp.json())
            .catch(this.handleError)
    }

    private handleError (error: Response | any) {
        // In a real world app, we might use a remote logging infrastructure
        //console.error('handleError:  ' + error);
        let errMsg: string;
        if (error instanceof Response) {
            const body = error.json() || '';
            const err = body.error || JSON.stringify(body);
            errMsg = `${error.status} - ${error.statusText || ''} ${err}`;
        } else {
            errMsg = error.message ? error.message : error.toString();
        }

        return Observable.throw(errMsg);
    }
}