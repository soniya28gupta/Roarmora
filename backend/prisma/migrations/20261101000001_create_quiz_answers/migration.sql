CREATE TABLE "quiz_answers" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "question_id" VARCHAR(80) NOT NULL,
    "category" VARCHAR(80) NOT NULL,
    "answer_value" VARCHAR(250) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "quiz_answers_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "quiz_answers_user_id_fkey"
        FOREIGN KEY ("user_id")
        REFERENCES "users"("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "quiz_answers_user_id_question_id_key"
ON "quiz_answers"("user_id", "question_id");