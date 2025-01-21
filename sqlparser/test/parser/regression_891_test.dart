import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

ColonVariableToken _colon(String name) {
  return ColonVariableToken(fakeSpan(':$name'), name);
}

void main() {
  final caseExpr = CaseExpression(
    whens: [
      WhenComponent(
        when: BinaryExpression(
          NumericLiteral(1),
          token(TokenType.equal),
          NamedVariable(_colon('isReviewFolderSelected')),
        ),
        then: IsExpression(
          true,
          Reference(entityName: 'n', columnName: 'nextReviewTime'),
          NullLiteral(),
        ),
      ),
    ],
    elseExpr: IsExpression(
      false,
      Reference(entityName: 'n', columnName: 'nextReviewTime'),
      NullLiteral(),
    ),
  );

  final folderExpr = BinaryExpression(
    Reference(entityName: 'n', columnName: 'folderId'),
    token(TokenType.equal),
    NamedVariable(_colon('selectedFolderId')),
  );

  test('repro 1', () {
    testStatement(
      '''
      SELECT * FROM notes n WHERE
        CASE
          WHEN 1 = :isReviewFolderSelected THEN n.nextReviewTime IS NOT NULL
          ELSE n.nextReviewTime IS NULL
         END
         and n.folderId = :selectedFolderId;
      ''',
      SelectStatement(
        from: TableReference('notes', as: 'n'),
        columns: [StarResultColumn()],
        where: BinaryExpression(
          caseExpr,
          token(TokenType.and),
          folderExpr,
        ),
      ),
    );
  });

  test('repro 2', () {
    testStatement(
      '''
      SELECT * FROM notes n WHERE 
      n.folderId = :selectedFolderId and
      CASE 
        WHEN 1 = :isReviewFolderSelected THEN n.nextReviewTime IS NOT NULL
        ELSE n.nextReviewTime IS NULL
      END;
      ''',
      SelectStatement(
        from: TableReference('notes', as: 'n'),
        columns: [StarResultColumn()],
        where: BinaryExpression(
          folderExpr,
          token(TokenType.and),
          caseExpr,
        ),
      ),
    );
  });
}
