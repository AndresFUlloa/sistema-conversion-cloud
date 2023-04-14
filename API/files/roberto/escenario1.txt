import { faker } from '@faker-js/faker';

import { AdminPage } from "../../pageObject/adminPage";
import { PublishedPostsPage } from "../../pageObject/publishedPostsPage";
import { MemberPage } from "../../pageObject/membersPage";

const adminPage = new AdminPage();
const publishedPostsPage = new PublishedPostsPage();
const memberPage = new MemberPage();
const correoRepetido = faker.internet.exampleEmail();

const escenario1 = {
    'a_priori': {
        'datos_validos' : 
            {
                titulo: 'nombre valido',
                descripcion: 'Descripcion valida'
            },
        'datos_formato_invalido' :
            {
                titulo: 'nombre valido',
                descripcion: 'Descripcion valida'
            },
        'datos_frontera_superior':
            {
                titulo: 'Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta)',
                descripcion: 'Descripcion valida'
            },
        'datos_frontera_inferior':
            {
                titulo: 'a',
                descripcion: 'Descripcion valida'
            },
        'campos_vacios':
            {
                titulo: '',
                descripcion: 'Descripcion valida'
            },
        'datos_equivocados':
            {
                titulo: '|||||',
                descripcion: 'Descripcion valida'
            },
        'datos_repetidos': 
            {
                titulo: 'correo@valido.com',
                descripcion: 'correo@valido.com',
            }
    },

    'aleatorio_dinámico': {
        'datos_validos' : 
            {
                titulo: faker.name.firstName(),
                descripcion: 'Descripcion valida'
            },
        'datos_formato_invalido' :
            {
                titulo: faker.name.firstName(),
                descripcion: faker.lorem.paragraph(5)
            },
        'datos_frontera_superior':
            {
                titulo: faker.lorem.paragraph(5),
                descripcion: 'Descripcion valida'
            },
        'datos_frontera_inferior':
            {
                titulo: faker.lorem.word({ strategy: 'shortest' }),
                descripcion: 'Descripcion valida'
            },
        'campos_vacios':
            {
                titulo: faker.name.firstName(),
                descripcion: 'Descripcion valida'
            },
        'datos_equivocados':
            {
                titulo: faker.internet.domainName(),
                descripcion: 'Descripcion valida'
            },
        'datos_repetidos': 
            {
                titulo: 'correo@valido.com',
                descripcion: 'correo@valido.com',
            }
    },

    'aleatorio': {
        'datos_validos' : 
            {
                titulo: faker.name.firstName(),
                descripcion: faker.lorem.paragraph(3)
            },
        'datos_formato_invalido' :
            {
                titulo: faker.name.firstName(),
                descripcion: faker.lorem.paragraph(3)
            },
        'datos_frontera_superior':
            {
                titulo: faker.lorem.paragraph(7),
                descripcion: faker.lorem.paragraph(3)
            },
        'datos_frontera_inferior':
            {
                titulo: faker.lorem.word({ strategy: 'shortest' }),
                descripcion: faker.lorem.paragraph(3)
            },
        'campos_vacios':
            {
                titulo: faker.name.firstName(),
                descripcion: ''
            },
        'datos_equivocados':
            {
                titulo: faker.internet.domainName(),
                descripcion: faker.lorem.paragraph(3)
            },
        'datos_repetidos': 
            {
                titulo: correoRepetido,
                descripcion: correoRepetido,
            }
    },
}

/*  Despues de hacer Login exitoso, quiero Agregar un nuevo Miembro y despues Crear un nuevo Post
 y espero que todos los pasos se puedan ejecutar correctamente */

for (let escenario in escenario1) {
        
        describe('Ghost tests ' + escenario, () => {
            beforeEach(() => {
                /* Given I log in into Ghost admin */
                cy.visit('http://localhost:2368/ghost')
                cy.login(Cypress.env('username'), Cypress.env('password'));
                cy.wait(1000);
            })

            for (let datoGenerado in escenario1[escenario]) {
                it('escenario 1.' + datoGenerado, () => {

                    let data = escenario1[escenario][datoGenerado];

                    /* When I create a new Member */
                    adminPage.navigateToMembersPage();
                    cy.createMember("Pablo Pineres", "pablo@gmail.com", "Ingeniero industrial que coordina proyectos de innovacion");
                    adminPage.navigateToMembersPage();
                    cy.wait(1000)
                    cy.reload();

                    /* And I expect to be able to see the Member */
                    adminPage.navigateToMembersPage();
                    cy.wait(1000);
                    membersPage.getAllMembersListNames().contains("Pablo Pineres").should("exist");

                    /* And then I create a new Post */
                    adminPage.navigateToMainPage();
                    cy.wait(500);
                    adminPage.getNewPostButton().click();
                    cy.wait(1000);
                    cy.createPost(data.titulo, data.descripcion);
                    cy.wait(500);

                    /* Then I expect to be able to see the post */
                    adminPage.navigateToPostsPage();
                    cy.wait(500);
                    adminPage.getPublishedPostsButton().click();
                    cy.wait(500);
                    publishedPostsPage
                    .getAllPostTitles()
                    .contains(data.titulo)
                    .should("exist");

                    /* Clean Up */
                    cy.wait(1000)
                    adminPage.navigateToMembersPage();
                    cy.wait(500);
                    cy.deleteAllMembers();
                    cy.wait(1000);

                    adminPage.navigateToPostsPage();
                    adminPage.getPublishedPostsButton().click();
                    cy.deleteAllPosts();
                    cy.wait(1000);

                })
        }
    })
}
